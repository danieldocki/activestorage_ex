defmodule ActivestorageEx.Variation do
  @moduledoc """
    A set of transformations that can be applied to a blob to create a variant.
  """

  @doc """
    Takes a map of `operations` and an `image_path`.  Each `operation` is then performed on
    the image, returning the image with operations queued
  """
  def transform(operations, image_path) when is_map(operations) do
    opened_image = Mogrify.open(image_path)

    apply_transformation(operations, opened_image)
  end

  defp apply_transformation([], image), do: image
  defp apply_transformation(operations, image) when map_size(operations) == 0, do: image
  defp apply_transformation(operations, image) do
    [{transformation, value} | rest] = Enum.to_list(operations)
    transformed_image = image |> Mogrify.custom(transformation, value)

    apply_transformation(rest, transformed_image)
  end
end
