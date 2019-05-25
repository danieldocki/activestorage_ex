defmodule ActivestorageEx.Variation do
  @moduledoc """
    A set of transformations that can be applied to a blob to create a variant.
  """

  @doc """
    An alias for encode/1
  """
  def key(transformations), do: encode(transformations)

  @doc """
    Returns a base64 encoded string from an list of transformations
  """
  def encode(transformations) when is_list(transformations) do
    ActivestorageEx.sign_message(%{transformations: transformations})
  end

  @doc """
    Returns a list of transformations from an encoded token
  """
  def decode(token) do
    {:ok, claims} = ActivestorageEx.verify_message(token)

    claims["transformations"]
  end

  @doc """
    Takes a map of `operations` and an `image_path`.  Each `operation` is then performed on
    the image, returning the image with operations queued
  """
  def transform(operations, image_path) when is_list(operations) do
    opened_image = Mogrify.open(image_path)

    apply_transformation(operations, opened_image)
  end

  defp apply_transformation([], image), do: image

  defp apply_transformation(operations, image) do
    [operation | rest] = Enum.to_list(operations)
    [{transformation, value}] = Map.to_list(operation)
    transformed_image = image |> Mogrify.custom(transformation, value)

    apply_transformation(rest, transformed_image)
  end
end
