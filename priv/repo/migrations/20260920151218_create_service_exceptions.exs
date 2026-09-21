defmodule TransportApi.Repo.Migrations.CreateServiceExceptions do
  use Ecto.Migration

  def change do
    create table(:service_exceptions) do
      add :feed_version_id, references(:feed_versions, on_delete: :delete_all), null: false
      add :service_id, references(:services, on_delete: :delete_all), null: false
      add :date, :date, null: false
      add :exception_type, :integer, null: false

      timestamps()
    end
    create unique_index(:service_exceptions, [:feed_version_id, :service_id, :date])
    end

end
