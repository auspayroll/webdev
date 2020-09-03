defmodule Webdev2.Repo.Migrations.AddSiteVector do
  use Ecto.Migration

  def change do
    alter table(:sites) do
      add :search_vector, :tsvector
    end
  end
end



