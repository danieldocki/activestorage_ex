defmodule ActivestorageEx.Variant do
  @moduledoc """
    Image blobs can have variants that are the result of a set of transformations
    applied to the original.  These variants are used to create thumbnails,
    fixed-size avatars, or any other derivative image from the original.

    Variants rely on ImageMagick for the actual transformations.
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
    Returns an identifying key for a given %Blob{} and set of transformations
  """
  def key(%Blob{} = blob, transformations) do
    variant_key = ActivestorageEx.Variation.key(transformations)
    hashed_variant_key = :crypto.hash(:sha256, variant_key) |> Base.encode16(case: :lower)

    "variants/#{blob.key}/#{hashed_variant_key}"
  end

  def key(%Variant{} = variant) do
    blob = struct(Blob, variant)

    key(blob, variant.transformations)
  end

  def processed(%Blob{} = blob, transformations) do
    variant = struct(Variant, Map.put(blob, :transformations, transformations))

    case processed?(variant) do
      true -> variant
      _ -> process(variant)
    end
  end

  def service_url(%Variant{} = variant) do
    blob = struct(Blob, variant)

    service_url(blob, variant.transformations)
  end

  def service_url(%Blob{} = blob, transformations, disposition \\ "inline") do
    key(blob, transformations)
    |> ActivestorageEx.service().url(%{
      content_type: content_type(blob),
      filename: filename(blob),
      disposition: disposition,
      token_duration: Application.get_env(:activestorage_ex, :jwt_expiration)
    })
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
