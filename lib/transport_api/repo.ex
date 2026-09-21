defmodule TransportApi.Repo do
  use Ecto.Repo,
    otp_app: :transport_api,
    adapter: Ecto.Adapters.Postgres
end
