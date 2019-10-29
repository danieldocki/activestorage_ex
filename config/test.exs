use Mix.Config

config :activestorage_ex,
  root_path: "external/activestorage_ex_rails/storage/",
  jwt_secret: "685fd35f346bd020447237213ad0798a",
  link_expiration: 60 * 5,
  asset_host: "http://localhost:4000",
  s3_bucket: "",
  service: ActivestorageEx.DiskService

import_config "secrets.exs"
