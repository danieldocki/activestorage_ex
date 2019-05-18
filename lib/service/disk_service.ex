defmodule ActivestorageEx.DiskService do
  @moduledoc """
    Wraps a local disk path as an ActivestorageEx service.
  """

  @doc """
    Returns a binary representation of an image for a given key
  """
  def download(key) do
    filepath_from_key = path_for(key)

    case File.open(filepath_from_key) do
      {:ok, io} -> IO.binread(io, :all)
      {:error, err} -> {:error, err}
    end
  end

  @doc """
    Returns the path to the folder containing a given key
  """
  def path_for(key) do
    Path.join(root_path(), [folder_for(key), "/", key])
  end

  defp folder_for(key) do
    [String.slice(key, 0..1), String.slice(key, 2..3)] |> Enum.join("/")
  end

  defp root_path() do
    Application.get_env(:activestorage_ex, :root_path)
  end
end
