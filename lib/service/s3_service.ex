defmodule ActivestorageEx.S3Service do
  @moduledoc """
    Wraps Amazon S3 as a storage service. Documentation mirrors that of `DiskService`.
  """
  @behaviour ActivestorageEx.Service

  alias ExAws.S3
  alias ActivestorageEx.Service

  def download(key) do
    case object_for(key) do
      {:ok, image} -> image.body
      _ -> {:error, :not_found}
    end
  end

  def stream_download(key, filepath) do
    # `download_file` operates in a streaming fashion by default
    S3.download_file(bucket_name(), key, filepath) |> ExAws.request!()

    {:ok, filepath}
  end

  def upload(image, key) do
    saved_image = image |> Mogrify.save()

    with {:ok, image_io} <- File.read(saved_image.path),
         {:ok, _} <- put_object_for(key, image_io) do
      remove_temp_file(saved_image.path)

      :ok
    else
      {:error, err} ->
        remove_temp_file(saved_image.path)

        {:error, err}
    end
  end

  def delete(key) do
    delete_request = S3.delete_object(bucket_name(), key) |> ExAws.request()

    case delete_request do
      {:ok, _} -> :ok
      {:error, err} -> {:error, err}
    end
  end

  def url(key, opts) do
    disposition = Service.content_disposition_with(opts[:disposition], opts[:filename])

    verified_key_with_expiration =
      ActivestorageEx.sign_message(
        %{
          key: key,
          disposition: disposition,
          content_type: opts[:content_type]
        },
        opts[:token_duration]
      )

    s3_url(verified_key_with_expiration, %{
      host: ActivestorageEx.env(:asset_host),
      disposition: disposition,
      content_type: opts[:content_type],
      filename: opts[:filename]
    })
  end

  def exist?(key) do
    case object_for(key) do
      {:ok, _} -> true
      _ -> false
    end
  end

  defp remove_temp_file(filepath) do
    File.rm(filepath)
  end

  defp put_object_for(key, image_io) do
    S3.put_object(bucket_name(), key, image_io) |> ExAws.request()
  end

  defp object_for(key) do
    S3.get_object(bucket_name(), key) |> ExAws.request()
  end

  defp bucket_name do
    ActivestorageEx.env(:s3_bucket)
  end

  defp s3_url(token, opts) do
    cleaned_filename = Service.sanitize(opts[:filename])
    whitelisted_opts = Map.take(opts, [:content_type, :disposition])
    base_url = "#{opts[:host]}/active_storage/s3/#{token}/#{cleaned_filename}"

    base_url
    |> URI.parse()
    |> Map.put(:query, URI.encode_query(whitelisted_opts))
    |> URI.to_string()
  end
end
