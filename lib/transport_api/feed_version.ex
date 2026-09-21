defmodule TransportApi.FeedVersion do
  use Ecto.Schema
  import Ecto.Changeset

  schema "feed_versions" do
    field :source, :string
    field :content_hash, :string
    field :status, :string
    field :started_at, :utc_datetime
    field :finished_at, :utc_datetime
    field :activated_at, :utc_datetime
    field :archive_path, :string

    has_many :stops, TransportApi.Stop
    has_many :routes, TransportApi.Route
    has_many :services, TransportApi.Service

    timestamps()
  end

  def changeset(feed_version, attrs) do
    feed_version
    |> cast(attrs, [:source,:content_hash,:status,:started_at,:finished_at,:activated_at, :archive_path])
    |> validate_required([:source, :content_hash])
    |> unique_constraint(:content_hash)
  end
end
