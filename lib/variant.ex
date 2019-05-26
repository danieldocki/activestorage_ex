defmodule ActivestorageEx.Variant do
  @moduledoc """
    Image blobs can have variants that are the result of a set of transformations
    applied to the original.  These variants are used to create thumbnails,
    fixed-size avatars, or any other derivative image from the original.

    Variants rely on ImageMagick for the actual transformations.

  ## Examples
    Variants are a struct with the following fields:
    ```
      %Variant{
        key: String,
        content_type: String,
        filename: String,
        transformations: [Map]
      }
    ```
  """

  @enforce_keys [:key, :content_type, :filename, :transformations]
  defstruct key: nil,
            content_type: nil,
            filename: nil,
            transformations: nil

  @web_image_content_types ["image/png", "image/jpeg", "image/jpg", "image/gif"]

  alias ActivestorageEx.Blob
  alias ActivestorageEx.Variant

  @doc """
    Returns an identifying key for a given `%Blob{}` and set of transformations

  ## Parameters
    - `blob`: A `%Blob{}` representing a root image. Presumably from the database
    - `transformations`: An ordered list of maps that represent valid ImageMagick commands
  ## Examples
    Generating a key from a blob and list of transformations

    ```
      blob = %Blob{}
      transformations = [%{resize: "50x50^"}, %{extent: "50x50"}]

      Variant.key(blob, transformations) # variant/blob_key/variant_key
    ```
  """
  def key(%Blob{} = blob, transformations) do
    variant_key = ActivestorageEx.Variation.key(transformations)
    hashed_variant_key = :crypto.hash(:sha256, variant_key) |> Base.encode16(case: :lower)

    "variants/#{blob.key}/#{hashed_variant_key}"
  end

  @doc """
    Returns an identifying key for a given `%Variant{}`.

    Delegates to `Variant.key(%Blob{}, transformations)`,
    handling the transformations automatically

  ## Parameters
    - `variant`: A `%Variant{}` created from a blob and list of transformations
  ## Examples
    Generating a key automatically from a variant

    ```
      variant = %Variant{}

      Variant.key(variant) # variant/blob_key/variant_key
    ```
  """
  def key(%Variant{} = variant) do
    blob = struct(Blob, Map.from_struct(variant))

    key(blob, variant.transformations)
  end

  @doc """
    Returns a variant matching `blob` and `transformations`
    or creates one if it doesn't exist

  ## Parameters
    - `blob`: A `%Blob{}` representing a root image. Presumably from the database
    - `transformations`: An ordered list of maps that represent valid ImageMagick commands
  ## Examples
    Retrieve a variant from a blob and list of transformations

    ```
      blob = %Blob{}
      transformations = [%{resize: "50x50^"}, %{extent: "50x50"}]

      Variant.processed(blob, transformations) # %Variant{}
    ```
  """
  def processed(%Blob{} = blob, transformations) do
    variant = struct(Variant, Map.put(Map.from_struct(blob), :transformations, transformations))

    case processed?(variant) do
      true -> variant
      _ -> process(variant)
    end
  end

  @doc """
    Returns a URL with the information required to represent a variant,
    taking the current file service into account

  ## Parameters
    - `blob`: A `%Blob{}` representing a root image. Presumably from the database
    - `transformations`: An ordered list of maps that represent valid ImageMagick commands
  ## Examples
    Retrieve a service URL from a blob and list of transformations

    ```
      blob = %Blob{}
      transformations = [%{resize: "50x50^"}, %{extent: "50x50"}]

      Variant.service_url(blob, transformations) # /active_storage/...
    ```
  """
  def service_url(%Blob{} = blob, transformations) do
    key(blob, transformations)
    |> ActivestorageEx.service().url(%{
      content_type: content_type(blob),
      filename: filename(blob),
      token_duration: Application.get_env(:activestorage_ex, :jwt_expiration)
    })
  end

  @doc """
    Returns a URL with the information required to represent a variant,
    taking the current file service into account.

    Delgates to `Variant.service_url(%Blob{}, transformations)`

  ## Parameters
    - `variant`: A `%Variant{}` created from a blob and list of transformations
  ## Examples
    Retrieve a service URL from a variant directly

    ```
      variant = %Variant{}

      Variant.service_url(variant) # /active_storage/...
    ```
  """
  def service_url(%Variant{} = variant) do
    blob = struct(Blob, Map.from_struct(variant))

    service_url(blob, variant.transformations)
  end

  defp content_type(%Blob{} = blob) do
    cond do
      invalid_image_content_type(blob) -> "image/png"
      true -> blob.content_type
    end
  end

  defp filename(%Blob{} = blob) do
    cond do
      invalid_image_content_type(blob) -> Path.basename(blob.filename) <> ".png"
      true -> blob.filename
    end
  end

  defp processed?(%Variant{} = variant) do
    key(variant) |> ActivestorageEx.service().exist?()
  end

  defp process(%Variant{} = variant) do
    key = variant.key
    filepath = key <> Path.extname(variant.filename)
    image = %Mogrify.Image{path: filepath} |> Mogrify.create()
    tempfile_location = image.path

    with :ok <- download_image(key, tempfile_location) do
      image
      |> transform(variant)
      |> format(variant)
      |> upload(variant)
    end

    remove_temp_file(tempfile_location)

    variant
  end

  defp download_image(key, filepath) do
    ActivestorageEx.service().stream_download(key, filepath)
  end

  defp transform(image, variant) do
    ActivestorageEx.Variation.transform(variant.transformations, image.path)
  end

  defp format(image, variant) do
    cond do
      invalid_image_content_type(variant) -> image |> Mogrify.format("png")
      true -> image
    end
  end

  defp upload(image, variant) do
    ActivestorageEx.service().upload(image, key(variant))
  end

  defp remove_temp_file(filepath) do
    File.rm(filepath)
  end

  defp invalid_image_content_type(variant) do
    !Enum.member?(@web_image_content_types, variant.content_type)
  end
end
