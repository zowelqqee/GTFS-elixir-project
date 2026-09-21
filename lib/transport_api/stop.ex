defmodule TransportApi.Stop do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stops" do
    field :gtfs_stop_id, :string
    field :name, :string
    field :lat, :float
    field :lon, :float
    field :location_type, :integer
    field :transport_type, :string

    belongs_to :feed_version, TransportApi.FeedVersion
    has_many :stop_times, TransportApi.StopTime

    timestamps()
  end

  def changeset(stop, attrs) do
    stop
    |> cast(attrs, [:feed_version_id, :gtfs_stop_id, :name, :lat, :lon, :location_type, :transport_type])
    |> validate_required([:feed_version_id, :gtfs_stop_id])
    |> unique_constraint([:feed_version_id, :gtfs_stop_id])
  end
end
