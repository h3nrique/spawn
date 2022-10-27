defmodule Statestores.Adapters.MSSQL.Migrations.CreateEventsTable do
  use Ecto.Migration

  def up do
    create table(:events, primary_key: false) do
      add :actor, :string, primary_key: true
      add :system, :string
      add :revision, :integer
      add :tags, :map
      add :data_type, :string
      add :data, :binary
      timestamps([type: :utc_datetime_usec])
    end
  end

  def down do
    drop table(:events)
  end
end