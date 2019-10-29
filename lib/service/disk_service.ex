defmodule ActivestorageEx.DiskService do
  @moduledoc """
    Wraps a local disk path as an ActivestorageEx service.

    `:root_path` in your config must be set.  Both blobs and
    variants are stored in folders with `:root_path` as the root
  """
  @behaviour ActivestorageEx.Service

  alias ActivestorageEx.Service

  @doc """
    Returns a binary representation of an image from a given `%Blob{}` or `%Variant{}` key

  ## Parameters
    - `key`: A `%Blob{}` or `%Variant{}`'s key
  ## Examples
    Downloading an image from a `%Blob{}` key

    ```
      blob = %Blob{}

      DiskService.download(blob.key) # {:ok, <<...>>}
    ```
  """
  def download(key) do
    case File.open(path_for(key)) do
      {:ok, io} -> IO.binread(io, :all)
      {:error, err} -> {:error, err}
    end
  end

  @doc """
    Downloads and saves a file to disk in a streaming fashion.
    Good for downloading large files

  ## Parameters
    - `key`: A `%Blob{}` or `%Variant{}`'s key
    - `filepath`: The desired filepath.  Note that directories will not be created
  ## Examples
    Downloading an image from a `%Blob{}` key

    ```
      blob = %Blob{}
      filepath = "storage/image.png"

      DiskService.stream_download(blob.key, filepath) # {:ok, "storage/image.png"}
    ```
  """
  def stream_download(key, filepath) do
    five_megabytes = 5 * 1024 * 1024

    path_for(key)
    |> File.stream!([], five_megabytes)
    |> Stream.into(File.stream!(filepath))
    |> Stream.run()

    {:ok, filepath}
  end

  @doc """
    Saves an `%Image{}` to disk, as determined by a given `%Blob{}` or `%Variant{}` key

  ## Parameters
    - `image`: A `%Mogrify.Image{}` that isn't persisted
    - `key`: The blob or variant's key.  File location will be based off this.
        Directories _will_ be created
  ## Examples
    Uploading an `%Image{}` to disk from a `%Blob{}` key

    ```
      image = %Mogrify.Image{}
      blob = %Blob{}

      DiskService.upload(image, blob.key) # %Mogrify.Image{}
    ```
  """
  def upload(image, key) do
    with :ok <- make_path_for(key) do
      image
      |> Mogrify.save()
      |> rename_image(key)

      :ok
    else
      {:error, err} -> {:error, err}
    end
  end

  @doc """
    Deletes an image based on its `key`

  ## Parameters
    - `key`: The blob or variant's key
  ## Examples
    Deleting a file from a `%Blob{}` key

    ```
      blob = %Blob{}

      DiskService.delete(blob.key)
    ```
  """
  def delete(key) do
    case File.rm(path_for(key)) do
      :ok -> :ok
      # Ignore files that don't exist
      {:error, :enoent} -> :ok
      {:error, err} -> {:error, err}
    end
  end

  @doc """
    Creates a URL with a signed token that represents an attachment's
    content type, disposition, and key.

    Expiration based off `token_duration` option
  ## Parameters
    - `key`: A `%Blob{}` or `%Variant{}`'s key
    - `opts`: A Map containing the following data:
      ```
        %{
          disposition: String, # Optional, but recommended
          filename: String, # Required
          content_type: String, # Required
          token_duration: nil | Integer # Optional.  `nil` will generate a non-expiring URL
        }
      ```
  ## Examples
    Getting an asset's URL from a `%Blob{}` key

    ```
      blob = %Blob{}
      opts = %{}

      DiskService.url(blob.key, opts) # /active_storage/...
    ```
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
    Returns the path on disk for a given `%Blob{}` or `%Variant{}` key

  ## Parameters
    - `key`: The blob or variant's key
  ## Examples
    Getting a path from a `%Blob{}` key

    ```
      blob = %Blob{}

      DiskService.path_for(blob.key) # storage/te/st/test_key
    ```
  """
  def path_for(key) do
    Path.join(root_path(), [folder_for(key), "/", key])
  end

  @doc """
    Returns whether a file for a given `%Blob{}` or `%Variant{}` key exists

  ## Parameters
    - `key`: The blob or variant's key
  ## Examples
    Determining file's existence from a `%Blob{}` key

    ```
      blob = %Blob{}

      DiskService.exist?(blob.key) # true
    ```
  """
  def exist?(key) do
    key
    |> path_for()
    |> File.exists?()
  end

  defp make_path_for(key) do
    key
    |> path_for()
    |> Path.dirname()
    |> File.mkdir_p()
  end

  defp folder_for(key) do
    [String.slice(key, 0..1), String.slice(key, 2..3)] |> Enum.join("/")
  end

  defp root_path do
    ActivestorageEx.env(:root_path)
  end

  defp rename_image(image, key) do
    File.copy!(image.path, path_for(key))
    File.rm!(image.path)

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
