defmodule TransportApi.Repo.Migrations.CreateStops do
  use Ecto.Migration

  def change do
    create table(:stops) do
      add :feed_version_id, references(:feed_versions, on_delete: :delete_all), null: false
      add :gtfs_stop_id, :string, null: false
      add :name, :string
      add :lat, :float
      add :lon, :float
      add :location_type, :integer
      add :transport_type, :string

      timestamps()
    end
  end
end
