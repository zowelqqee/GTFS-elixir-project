defmodule TransportApi.Repo.Migrations.CreateStopTimes do
  use Ecto.Migration

  def change do
    create table(:stop_times) do
      add :feed_version_id, references(:feed_versions, on_delete: :delete_all), null: false
      add :trip_id, references(:trips, on_delete: :delete_all), null: false
      add :stop_id, references(:stops, on_delete: :delete_all), null: false
      add :stop_sequence, :integer, null: false
      add :arrival_sec, :integer
      add :departure_sec, :integer
      add :shape_dist_traveled, :float
      add :segment_shape_id, references(:shapes, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:stop_times, [:feed_version_id, :trip_id, :stop_sequence])
    create index(:stop_times, [:feed_version_id, :stop_id, :departure_sec])
  end
end
