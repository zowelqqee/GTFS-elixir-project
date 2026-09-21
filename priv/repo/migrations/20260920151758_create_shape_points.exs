defmodule TransportApi.Repo.Migrations.CreateShapePoints do
  use Ecto.Migration

  def change do
    create table(:shape_points) do
      add :feed_version_id, references(:feed_versions, on_delete: :delete_all), null: false
      add :shape_id, references(:shapes, on_delete: :delete_all), null: false
      add :seq, :integer, null: false
      add :lat, :float, null: false
      add :lon, :float, null: false
      add :dist_traveled, :float

      timestamps()
    end

    create unique_index(:shape_points, [:feed_version_id, :shape_id, :seq])
  end
end
