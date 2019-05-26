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

      Variant.key(blob, transformations)
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

      Variant.key(variant)
    ```
  """
  def key(%Variant{} = variant) do
    blob = struct(Blob, variant)

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

      Variant.processed(blob, transformations)
    ```
  """
  def processed(%Blob{} = blob, transformations) do
    variant = struct(Variant, Map.put(blob, :transformations, transformations))

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

      Variant.service_url(blob, transformations)
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

      Variant.service_url(variant)
    ```
  """
  def service_url(%Variant{} = variant) do
    blob = struct(Blob, variant)

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
    extension = Path.extname(variant.filename)
    image = %Mogrify.Image{path: key <> extension} |> Mogrify.create()

    with :ok <- download_image(key, image.path) do
      image
      |> transform(variant)
      |> format(variant)
      |> upload(variant)
      |> remove_temp_file()
    end

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

  defp remove_temp_file(image) do
    File.rm!(image.path)

    image
  end

  defp invalid_image_content_type(variant) do
    !Enum.member?(@web_image_content_types, variant.content_type)
  end
end
