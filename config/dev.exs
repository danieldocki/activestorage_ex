use Mix.Config

config :activestorage_ex,
  root_path: "/",
  jwt_secret: "",
  jwt_expiration: 60 * 5,
  asset_host: ""

import_config "secrets.exs"
