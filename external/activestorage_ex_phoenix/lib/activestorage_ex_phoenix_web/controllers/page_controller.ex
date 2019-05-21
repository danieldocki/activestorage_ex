defmodule ActivestorageExPhoenixWeb.PageController do
  use ActivestorageExPhoenixWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
