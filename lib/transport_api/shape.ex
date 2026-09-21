defmodule TransportApi.Shape do
  use Ecto.Schema
  import Ecto.Changeset

  schema "shapes" do
    field :gtfs_shape_id, :string
    field :length, :float
    field :point_count, :integer

    belongs_to :feed_version, TransportApi.FeedVersion

    has_many :shape_points, TransportApi.ShapePoint
    has_many :trips, TransportApi.Trip

    timestamps()
  end

  def changeset(shape, attrs) do
    shape
    |> cast(attrs, [
      :feed_version_id,
      :gtfs_shape_id,
      :length,
      :point_count
    ])
    |> validate_required([
      :feed_version_id,
      :gtfs_shape_id
    ])
    |> unique_constraint([:feed_version_id, :gtfs_shape_id])
  end
end
