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
    Creates a URL with a signed token that represents an attachment's
    content type, disposition, and key.

    Expiration based off `jwt_expiration` config var
  """
  def url(key, opts) do
    # TODO
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
    ActivestorageEx.env(:root_path)
  end

  defp sign_jwt(payload) do
    current_time = DateTime.utc_now() |> DateTime.to_unix()
    token_duration = ActivestorageEx.env(:jwt_expiration) || 0

    JWT.sign(payload, %{
      key: jwt_secret(),
      exp: current_time + token_duration
    })
  end

  defp jwt_secret() do
    ActivestorageEx.env(:jwt_secret)
  end
end
