defmodule TransportApi.Repo.Migrations.CreateFrequencies do
  use Ecto.Migration

  def change do
    create table (:frequencies) do
      add :feed_version_id, references(:feed_versions, on_delete: :delete_all), null: false
      add :trip_id, references(:trips, on_delete: :delete_all), null: false
      add :start_sec, :integer, null: false
      add :end_sec, :integer, null: false
      add :headway_secs, :integer, null: false
      add :exact_times, :integer

      timestamps()
    end
    create unique_index(:frequencies, [:feed_version_id, :trip_id, :start_sec])
  end
end
