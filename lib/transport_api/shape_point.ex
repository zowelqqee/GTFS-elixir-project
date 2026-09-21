defmodule TransportApi.ShapePoint do
  use Ecto.Schema
  import Ecto.Changeset

  schema "shape_points" do
    field :seq, :integer
    field :lat, :float
    field :lon, :float
    field :dist_traveled, :float

    belongs_to :feed_version, TransportApi.FeedVersion
    belongs_to :shape, TransportApi.Shape

    timestamps()
  end

  def changeset(shape_point, attrs) do
    shape_point
    |> cast(attrs, [
      :feed_version_id,
      :shape_id,
      :seq,
      :lat,
      :lon,
      :dist_traveled
    ])
    |> validate_required([
      :feed_version_id,
      :shape_id,
      :seq,
      :lat,
      :lon
    ])
  end
end
