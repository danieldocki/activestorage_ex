defmodule ActivestorageEx.Variant do
  @moduledoc """
    Image blobs can have variants that are the result of a set of transformations applied to the original.
    These variants are used to create thumbnails, fixed-size avatars, or any other derivative image from the original.

    Variants rely on ImageMagick for the actual transformations.
  """

  @doc """
    Returns an identifying key for a given blob and set of transformations
  """
  def key(blob, transformations) do
    variant_key = ActivestorageEx.Variation.key(transformations)
    hashed_variant_key = :crypto.hash(:sha256, variant_key) |> Base.encode16()

    "variants/#{blob[:key]}/#{hashed_variant_key}"
  end

  # def processed(blob) do
  #   case processed?(blob) do
  #     true -> blob
  #     _ -> process(blob)
  #   end
  # end

  # defp processed?(variant) do
  #   false
  # end

  # defp process(variant) do
  # end
end
