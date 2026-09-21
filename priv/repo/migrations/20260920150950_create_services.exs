defmodule TransportApi.Repo.Migrations.CreateServices do
  use Ecto.Migration

  def change do
    create table(:services) do
      add :feed_version_id, references(:feed_versions, on_delete: :delete_all), null: false
      add :gtfs_service_id, :string, null: false
      add :monday, :boolean
      add :tuesday, :boolean
      add :wednesday, :boolean
      add :thursday, :boolean
      add :friday, :boolean
      add :saturday, :boolean
      add :sunday, :boolean
      add :start_date, :date
      add :end_date, :date
      add :name, :string
      timestamps()
    end
    create unique_index(:services, [:feed_version_id, :gtfs_service_id])
  end
end
