defmodule Webdev2.Repo.Migrations.UsernameIndex do
  use Ecto.Migration

  def change do
	create unique_index(:users, [:username])
  end
end
