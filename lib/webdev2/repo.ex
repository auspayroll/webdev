defmodule Webdev2.Repo do
  use Ecto.Repo,
    otp_app: :webdev2,
    adapter: Ecto.Adapters.Postgres
end

defmodule Webdev2.Ecto.Types.TSVectorType do
  @behaviour Ecto.Type

  def type, do: :tsvector

  def cast(tsvector), do: {:ok, tsvector}

  def load(tsvector), do: {:ok, tsvector}

  def dump(tsvector), do: {:ok, tsvector}
end
