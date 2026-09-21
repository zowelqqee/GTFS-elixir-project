defmodule TransportApi.ServiceException do
  use Ecto.Schema
  import Ecto.Changeset

  schema "service_exceptions" do
    field :date, :date
    field :exception_type, :integer

    belongs_to :feed_version, TransportApi.FeedVersion
    belongs_to :service, TransportApi.Service

    timestamps()
  end

  def changeset(service_exception, attrs) do
    service_exception
    |> cast(attrs, [
      :feed_version_id,
      :service_id,
      :date,
      :exception_type
    ])
    |> validate_required([
      :feed_version_id,
      :service_id,
      :date,
      :exception_type
    ])
  end
end
