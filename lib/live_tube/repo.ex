defmodule LiveTube.Repo do
  use Ecto.Repo,
    otp_app: :live_tube,
    adapter: Ecto.Adapters.Postgres
end
