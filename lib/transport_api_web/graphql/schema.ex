defmodule TransportApiWeb.Schema do
  use Absinthe.Schema
  import Ecto.Query

  alias TransportApi.Repo
  alias TransportApi.Stop

  object :stop do
    field :id, :id
    field :gtfs_stop_id, :string
    field :name, :string
    field :lat, :float
    field :lon, :float
    field :location_type, :integer
    field :transport_type, :string
  end

  object :trip do
    field :id, :id
    field :gtfs_trip_id, :string
    field :direction_id, :integer
    field :route_id, :id
    field :service_id, :id
  end

  object :stop_time do
    field :id, :id
    field :trip_id, :id
    field :stop_id, :id
    field :stop_sequence, :integer
    field :arrival_sec, :integer
    field :departure_sec, :integer
  end

  query do
    field :stops, list_of(:stop) do
      resolve(fn _, _, _ -> {:ok, Repo.all(Stop)} end)
    end
    field :trips, list_of(:trip) do
      resolve(fn _, _, _ -> {:ok, Repo.all(TransportApi.Trip)} end)
    end
    field :schedule, list_of(:stop_time) do
      arg :stop_id, non_null(:id)

      resolve(fn _, %{stop_id: stop_id}, _ ->
        stop_times =
          TransportApi.StopTime
          |> Ecto.Query.where([st], st.stop_id == ^stop_id)
          |> Repo.all()

        {:ok, stop_times}
      end)
    end
end
end
