defmodule TransportApi.Repo.Migrations.AddArchivePathToFeedVersions do
  use Ecto.Migration

  def change do
    alter table(:feed_versions) do
      add :archive_path, :string
    end
  end
end
