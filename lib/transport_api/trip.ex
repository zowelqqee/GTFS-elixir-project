defmodule TransportApi.Trip do
  use Ecto.Schema
  import Ecto.Changeset

  schema "trips" do
    field :gtfs_trip_id, :string
    field :direction_id, :integer

    belongs_to :feed_version, TransportApi.FeedVersion
    belongs_to :route, TransportApi.Route
    belongs_to :service, TransportApi.Service
    belongs_to :shape, TransportApi.Shape

    has_many :stop_times, TransportApi.StopTime
    has_many :frequencies, TransportApi.Frequency

    timestamps()
  end

  def changeset(trip, attrs) do
    trip
    |> cast(attrs, [
      :feed_version_id,
      :gtfs_trip_id,
      :route_id,
      :service_id,
      :direction_id,
      :shape_id
    ])
    |> validate_required([
      :feed_version_id,
      :gtfs_trip_id,
      :route_id,
      :service_id
    ])
    |> unique_constraint([:feed_version_id, :gtfs_trip_id])
  end
end
