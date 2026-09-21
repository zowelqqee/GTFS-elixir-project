defmodule TransportApi.Repo.Migrations.CreateShapes do
  use Ecto.Migration

  def change do
    create table(:shapes) do
      add :feed_version_id, references(:feed_versions, on_delete: :delete_all),null: false

      add :gtfs_shape_id, :string, null: false
      add :length, :float
      add :point_count, :integer

      timestamps()
    end

    create unique_index(:shapes, [:feed_version_id, :gtfs_shape_id])
  end
end
