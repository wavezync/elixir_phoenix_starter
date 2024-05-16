defmodule ElixirPhoenixStarter.Repo do
  use Ecto.Repo,
    otp_app: :elixir_phoenix_starter,
    adapter: Ecto.Adapters.Postgres
end
