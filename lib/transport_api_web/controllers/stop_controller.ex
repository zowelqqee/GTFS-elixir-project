defmodule TransportApiWeb.StopController do
  use TransportApiWeb, :controller

  alias TransportApi.Repo
  alias TransportApi.Stop

  def index(conn, _params) do
    stops =
      Stop
      |> Repo.all()
      |> Enum.map(fn stop -> %{
        id: stop.id,
        gtfs_stop_id: stop.gtfs_stop_id,
        name: stop.name,
        lat: stop.lat,
        lon: stop.lon,
        location_type: stop.location_type,
        transport_type: stop.transport_type
      } end)
    json(conn, stops)
  end
end
