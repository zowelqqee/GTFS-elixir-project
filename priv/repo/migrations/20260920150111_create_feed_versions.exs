defmodule TransportApi.Repo.Migrations.CreateFeedVersions do
  use Ecto.Migration

  def change do
    create table(:feed_versions) do
      add :version, :string
      add :content_hash, :string
      add :status, :string

      add :started_at, :utc_datetime
      add :finished_at, :utc_datetime
      add :activated_at, :utc_datetime
      timestamps()
  end

  create unique_index(:feed_versions, [:content_hash])
end
end
