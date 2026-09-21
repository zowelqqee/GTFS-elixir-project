defmodule TransportApi.Service do
  use Ecto.Schema
  import Ecto.Changeset

  schema "services" do
    field :gtfs_service_id, :string
    field :monday, :boolean
    field :tuesday, :boolean
    field :wednesday, :boolean
    field :thursday, :boolean
    field :friday, :boolean
    field :saturday, :boolean
    field :sunday, :boolean
    field :start_date, :date
    field :end_date, :date
    field :name, :string

    belongs_to :feed_version, TransportApi.FeedVersion
    has_many :trips, TransportApi.Trip
    has_many :service_exceptions, TransportApi.ServiceException

    timestamps()
  end

  def changeset(service, attrs) do
    service
    |> cast(attrs, [
      :feed_version_id,
      :gtfs_service_id,
      :monday,
      :tuesday,
      :wednesday,
      :thursday,
      :friday,
      :saturday,
      :sunday,
      :start_date,
      :end_date,
      :name
    ])
    |> validate_required([:feed_version_id, :gtfs_service_id])
    |> unique_constraint([:feed_version_id, :gtfs_service_id])
  end
end
