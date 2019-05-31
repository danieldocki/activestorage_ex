defmodule ActivestorageEx.S3Service do
  @moduledoc """
    Wraps Amazon S3 as a storage service.
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
    S3.download_file(bucket_name(), key, filepath) |> ExAws.request!

    {:ok, filepath}
  end

  def upload(image, key) do
    saved_image = image |> Mogrify.save()

    with {:ok, image_io} <- File.read(saved_image.path),
      {:ok, _} <- put_object_for(key, image_io)
    do
      remove_temp_file(saved_image.path)

      :ok
    else
      {:error, err} ->
        remove_temp_file(saved_image.path)

        {:error, err}
    end
  end

  def delete(key) do
    delete_request = S3.delete_object(bucket_name(), key) |> ExAws.request

    case delete_request do
      {:ok, _} -> :ok
      {:error, err} -> {:error, err}
    end
  end

  def url(key, opts) do
    disposition = Service.content_disposition_with(opts[:disposition], opts[:filename])
    s3_config = ExAws.Config.new(:s3, [])
    url_options = [
      expires_in: ActivestorageEx.env(:link_expiration),
      query_params: [
        response_content_disposition: disposition,
        response_content_type: opts[:content_type]
      ]
    ]

    {:ok, url} = S3.presigned_url(s3_config, :get, bucket_name(), key, url_options)

    url
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
    S3.put_object(bucket_name(), key, image_io) |> ExAws.request
  end

  defp object_for(key) do
    S3.get_object(bucket_name(), key) |> ExAws.request
  end

  defp bucket_name do
    ActivestorageEx.env(:s3_bucket)
  end
end
