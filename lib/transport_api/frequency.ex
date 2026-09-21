defmodule TransportApi.Frequency do
  use Ecto.Schema
  import Ecto.Changeset

  schema "frequencies" do
    field :start_sec, :integer
    field :end_sec, :integer
    field :headway_secs, :integer
    field :exact_times, :integer

    belongs_to :feed_version, TransportApi.FeedVersion
    belongs_to :trip, TransportApi.Trip

    timestamps()
  end

  def changeset(frequency, attrs) do
    frequency
    |> cast(attrs, [
      :feed_version_id,
      :trip_id,
      :start_sec,
      :end_sec,
      :headway_secs,
      :exact_times
    ])
    |> validate_required([
      :feed_version_id,
      :trip_id,
      :start_sec,
      :end_sec,
      :headway_secs
    ])
  end
end
