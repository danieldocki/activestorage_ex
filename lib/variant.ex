defmodule ActivestorageEx.Variant do
  @moduledoc """
    Image blobs can have variants that are the result of a set of transformations
    applied to the original.  These variants are used to create thumbnails,
    fixed-size avatars, or any other derivative image from the original.

    Variants rely on ImageMagick for the actual transformations.
  """

  @web_image_content_types ["image/png", "image/jpeg", "image/jpg", "image/gif"]

  @doc """
    Returns an identifying key for a given blob and set of transformations
  """
  def key(blob, transformations) do
    variant_key = ActivestorageEx.Variation.key(transformations)
    hashed_variant_key = :crypto.hash(:sha256, variant_key) |> Base.encode16(case: :lower)

    "variants/#{blob[:key]}/#{hashed_variant_key}"
  end

  def processed(blob, transformations) do
    blob_with_transformations = Map.put(blob, :transformations, transformations)

    case processed?(blob_with_transformations) do
      true -> blob_with_transformations
      _ -> process(blob_with_transformations)
    end
  end

  def service_url(%{transformations: transformations} = blob) do
    service_url(blob, transformations)
  end

  def service_url(blob, transformations) do
    key(blob, transformations)
    |> ActivestorageEx.service().url(%{
      content_type: content_type(blob),
      filename: filename(blob),
      token_duration: Application.get_env(:activestorage_ex, :jwt_expiration)
    })
  end

  defp content_type(blob) do
    cond do
      invalid_image_content_type(blob) -> "image/png"
      true -> blob[:content_type]
    end
  end

  defp filename(blob) do
    cond do
      invalid_image_content_type(blob) -> Path.basename(blob[:filename]) <> ".png"
      true -> blob[:filename]
    end
  end

  defp processed?(blob) do
    key(blob, blob[:transformations]) |> ActivestorageEx.service().exist?()
  end

  defp process(blob) do
    key = blob[:key]
    extension = Path.extname(blob[:filename])
    image = %Mogrify.Image{path: key <> extension} |> Mogrify.create()

    with :ok <- download_image(key, image.path) do
      image
      |> transform(blob)
      |> format(blob)
      |> upload(blob)
    end

    blob
  end

  defp download_image(key, filepath) do
    ActivestorageEx.service().stream_download(key, filepath)
  end

  defp transform(image, blob) do
    ActivestorageEx.Variation.transform(blob[:transformations], image.path)
  end

  defp format(image, blob) do
    cond do
      invalid_image_content_type(blob) -> image |> Mogrify.format("png")
      true -> image
    end
  end

  defp upload(image, blob) do
    ActivestorageEx.service().upload(image, key(blob, blob[:transformations]))
  end

  defp invalid_image_content_type(blob) do
    !Enum.member?(@web_image_content_types, blob[:content_type])
  end
end
