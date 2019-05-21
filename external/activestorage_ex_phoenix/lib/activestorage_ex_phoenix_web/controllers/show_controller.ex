defmodule ActivestorageExPhoenixWeb.ShowController do
  use ActivestorageExPhoenixWeb, :controller

  def index(conn, params) do
    json(conn, %{
      url:
        ActivestorageEx.DiskService.url(params["blob_name"], %{
          disposition: "attachment",
          filename: "something.png",
          content_type: "image/png",
          token_duration: Application.get_env(:activestorage_ex, :jwt_expiration)
        })
    })
  end
end
