use Mix.Config

config :activestorage_ex,
  root_path: "/",
  jwt_secret: "",
  link_expiration: 60 * 5,
  asset_host: "",
  s3_bucket: ""

import_config "secrets.exs"
