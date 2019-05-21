defmodule ActivestorageExPhoenixWeb.Router do
  use ActivestorageExPhoenixWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", ActivestorageExPhoenixWeb do
    pipe_through(:browser)

    get("/show/:blob_name", ShowController, :index)
    get("/active_storage/disk/:token/:filename", DiskController, :index)
  end

  # Other scopes may use custom stacks.
  # scope "/api", ActivestorageExPhoenixWeb do
  #   pipe_through :api
  # end
end
