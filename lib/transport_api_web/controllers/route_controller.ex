defmodule TransportApiWeb.RouteController do
  use TransportApiWeb, :controller

  alias TransportApi.Repo
  alias TransportApi.Route

  @spec index(Plug.Conn.t(), any()) :: Plug.Conn.t()

  def index(conn, _params) do
    routes =
      Route
      |> Repo.all()
      |> Enum.map(fn route ->
        %{
          id: route.id,
          gtfs_route_id: route.gtfs_route_id,
          short_name: route.short_name,
          long_name: route.long_name,
          route_type: route.route_type,
          transport_type: route.transport_type,
          circular: route.circular,
          urban: route.urban
        }
      end)

    json(conn, routes)
  end
end
