defmodule Webdev2.Repo.Migrations.CreateSites do
  use Ecto.Migration

  def change do
    create table(:sites) do
      add :tags, :string
      add :title, :string
      add :url, :string
      add :body, :text

      timestamps()
    end

  end
end
