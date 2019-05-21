defmodule ActivestorageExPhoenixWeb.DiskController do
  use ActivestorageExPhoenixWeb, :controller

  def index(conn, params) do
    {:ok, claims} =
      JWT.verify(params["token"], %{
        key: Application.get_env(:activestorage_ex, :jwt_secret)
      })

    conn
    |> put_resp_content_type(claims["content_type"])
    |> put_resp_header("Content-Disposition", claims["disposition"])
    |> send_resp(:ok, ActivestorageEx.DiskService.download(claims["key"]))
  end
end
