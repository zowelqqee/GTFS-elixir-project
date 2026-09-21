defmodule TransportApi.Repo.Migrations.AddRoutingIndexes do
  use Ecto.Migration

  def change do
    create index(:stop_times, [:stop_id, :departure_sec])
    create index(:stop_times, [:trip_id, :stop_sequence])
    create index(:stop_times, [:stop_id, :trip_id])
  end
end
