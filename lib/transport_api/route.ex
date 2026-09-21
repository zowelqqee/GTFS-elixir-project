defmodule TransportApi.Route do
  use Ecto.Schema
  import Ecto.Changeset

  schema "routes" do
    field :gtfs_route_id, :string
    field :short_name, :string
    field :long_name, :string
    field :route_type, :integer
    field :transport_type, :string
    field :circular, :boolean
    field :urban, :boolean

    belongs_to :feed_version, TransportApi.FeedVersion
    has_many :trips, TransportApi.Trip

    timestamps()
  end

  def changeset(route, attrs) do
    route
    |> cast(attrs, [:feed_version_id, :gtfs_route_id, :short_name, :long_name, :route_type, :transport_type, :circular, :urban])
    |> validate_required([:feed_version_id, :gtfs_route_id])
    |> unique_constraint([:feed_version_id, :gtfs_route_id])
  end
end
