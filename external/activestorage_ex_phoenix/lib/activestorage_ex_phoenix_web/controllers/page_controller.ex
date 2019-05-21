defmodule ActivestorageExPhoenixWeb.PageController do
  use ActivestorageExPhoenixWeb, :controller

  def index(conn, _params) do
    send_resp(conn, :ok, ActivestorageEx.DiskService.download("4kR4sshQ7uCJaP8jgsXAYmAP"))
  end
end
