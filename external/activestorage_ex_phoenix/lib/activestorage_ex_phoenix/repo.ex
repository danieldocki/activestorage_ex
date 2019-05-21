defmodule ActivestorageExPhoenix.Repo do
  use Ecto.Repo,
    otp_app: :activestorage_ex_phoenix,
    adapter: Ecto.Adapters.Postgres
end
