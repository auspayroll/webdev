defmodule Webdev2.Repo.Migrations.AddSiteUser do
  use Ecto.Migration

  def change do
	alter table(:sites) do
		add :user_id, references(:users, on_delete: :delete_all) #, null: false
	end
  end
end
