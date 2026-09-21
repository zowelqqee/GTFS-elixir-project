defmodule TransportApi.Repo.Migrations.CreateRoutes do
  use Ecto.Migration

  def change do
    create table(:routes) do
      add :feed_version_id, references(:feed_versions, on_delete: :delete_all), null: false
      add :gtfs_route_id, :string, null: false
      add :short_name, :string
      add :long_name, :string
      add :route_type, :integer
      add :transport_type, :string
      add :circular, :boolean
      add :urban, :boolean

      timestamps()
    end
    create unique_index(:routes, [:feed_version_id, :gtfs_route_id])
  end
end
