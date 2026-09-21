defmodule TransportApi.StopTime do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stop_times" do
    field :stop_sequence, :integer
    field :arrival_sec, :integer
    field :departure_sec, :integer
    field :shape_dist_traveled, :float

    belongs_to :feed_version, TransportApi.FeedVersion
    belongs_to :trip, TransportApi.Trip
    belongs_to :stop, TransportApi.Stop
    belongs_to :segment_shape, TransportApi.Shape

    timestamps()
  end

  def changeset(stop_time, attrs) do
    stop_time
    |> cast(attrs, [
      :feed_version_id,
      :trip_id,
      :stop_id,
      :stop_sequence,
      :arrival_sec,
      :departure_sec,
      :shape_dist_traveled,
      :segment_shape_id
    ])
    |> validate_required([
      :feed_version_id,
      :trip_id,
      :stop_id,
      :stop_sequence
    ])
  end
end
