defmodule ActivestorageEx.DiskService do
  @moduledoc """
    Wraps a local disk path as an ActivestorageEx service.
  """

  alias ActivestorageEx.Service

  @doc """
    Returns a binary representation of an image for a given key
  """
  def download(key) do
    case File.open(path_for(key)) do
      {:ok, io} -> IO.binread(io, :all)
      {:error, err} -> {:error, err}
    end
  end

  def stream_download(key, filepath) do
    five_megabytes = 5 * 1024 * 1024

    File.stream!(path_for(key), [], five_megabytes)
    |> Stream.into(File.stream!(filepath))
    |> Stream.run()
  end

  def upload(image, key) do
    with :ok <- make_path_for(key) do
      image
      |> Mogrify.save()
      |> rename_image(key)
    end
  end

  def make_path_for(key) do
    key
    |> path_for()
    |> Path.dirname()
    |> File.mkdir_p()
  end

  @doc """
    Creates a URL with a signed token that represents an attachment's
    content type, disposition, and key.

    Expiration based off `token_duration` option
  """
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

    disk_service_url(verified_key_with_expiration, %{
      host: ActivestorageEx.env(:asset_host),
      disposition: disposition,
      content_type: opts[:content_type],
      filename: opts[:filename]
    })
  end

  @doc """
    Returns the path to the folder containing a given key
  """
  def path_for(key) do
    Path.join(root_path(), [folder_for(key), "/", key])
  end

  def exist?(key) do
    key
    |> path_for()
    |> File.exists?()
  end

  defp folder_for(key) do
    [String.slice(key, 0..1), String.slice(key, 2..3)] |> Enum.join("/")
  end

  defp root_path() do
    ActivestorageEx.env(:root_path)
  end

  defp rename_image(image, key) do
    File.rename(image.path, path_for(key))

    image
  end

  defp disk_service_url(token, opts) do
    cleaned_filename = Service.sanitize(opts[:filename])
    whitelisted_opts = Map.take(opts, [:content_type, :disposition])
    base_url = "#{opts[:host]}/active_storage/disk/#{token}/#{cleaned_filename}"

    base_url
    |> URI.parse()
    |> Map.put(:query, URI.encode_query(whitelisted_opts))
    |> URI.to_string()
  end
end
