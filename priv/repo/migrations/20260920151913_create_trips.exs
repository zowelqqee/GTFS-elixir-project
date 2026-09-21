defmodule TransportApi.Repo.Migrations.CreateTrips do
  use Ecto.Migration

  def change do
    create table(:trips) do
      add :feed_version_id, references(:feed_versions, on_delete: :delete_all), null: false
      add :gtfs_trip_id, :string, null: false
      add :route_id, references(:routes, on_delete: :delete_all), null: false
      add :service_id, references(:services, on_delete: :delete_all), null: false
      add :direction_id, :integer
      add :shape_id, references(:shapes, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:trips, [:feed_version_id, :gtfs_trip_id])
    create index(:trips, [:route_id])
    create index(:trips, [:service_id])
    create index(:trips, [:shape_id])
  end
end
