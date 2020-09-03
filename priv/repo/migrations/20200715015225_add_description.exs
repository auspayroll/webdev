defmodule Webdev2.Repo.Migrations.AddDescription do
  use Ecto.Migration

  def change do
	alter table(:sites) do
		add :description, :string
	end

  end
end
