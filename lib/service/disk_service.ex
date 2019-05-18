defmodule ActivestorageEx.DiskService do
  @moduledoc """
    Wraps a local disk path as an ActivestorageEx service.
  """

  @doc """
    Returns the path to the folder containing a given key
  """
  def path_for(root, key) do
    Path.join([root, folder_for(key), key])
  end

  defp folder_for(key) do
    [String.slice(key, 0..1), String.slice(key, 2..3)] |> Enum.join("/")
  end
end
