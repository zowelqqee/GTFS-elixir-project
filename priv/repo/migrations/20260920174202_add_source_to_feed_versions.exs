defmodule TransportApi.Repo.Migrations.AddSourceToFeedVersions do
  use Ecto.Migration

  def change do
    alter table(:feed_versions) do
      add :source, :string
    end
  end
end
