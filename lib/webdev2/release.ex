defmodule Webdev2.Release do
    @app :webdev2
  
    def migrate do
      load_app()
  
      for repo <- repos() do
        {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
      end
    end
  
    def rollback(repo, version) do
      load_app()
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
    end
  
    def repos do
      Application.fetch_env!(@app, :ecto_repos)
    end

    defp load_app do
      Application.load(@app)
    end

    def showdb do
      IO.puts System.get_env("DATABASE")
    end

end