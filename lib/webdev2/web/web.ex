defmodule Webdev2.Web do
  @moduledoc """
  The Web context.
  """

  import Ecto.Query, warn: false
  alias Webdev2.Repo
  use Ecto.Schema
  alias Webdev2.Web.Site

  def search_site(query_string, page, user_id) do
      query = from s in Site, 
        select_merge: %{ranking: fragment("ts_rank(search_vector, websearch_to_tsquery('english', ?), 32 ) as ranking", ^query_string)},
        where: fragment("search_vector @@ websearch_to_tsquery('english', ?) and user_id = ?", ^query_string, ^user_id),
        order_by: fragment("ranking desc")
      Paginator.paginate(Webdev2.Repo, query, page) 
  end

  def reindex(user_id) do
    query = "UPDATE sites SET search_vector =
    setweight(to_tsvector(coalesce(sites.tags,'')), 'A') ||
    setweight(to_tsvector(coalesce(sites.title,'')), 'B') ||
    setweight(to_tsvector(coalesce(sites.body,'')), 'C') ||
    setweight(to_tsvector(coalesce(sites.url,'')), 'D')
    where user_id = $1;"
    Ecto.Adapters.SQL.query!(Repo, query , [user_id])
  end

  def list_sites(id, user_id) do
    query = from s in Site, where: s.user_id == ^user_id, order_by: [desc: s.inserted_at]
    Paginator.paginate(Repo, query, id)
  end

  def get_site!(id, user_id), do: Repo.get_by!(Site, id: id, user_id: user_id)

  def update_or_create_site(attrs \\ %{}, user) do
    try do 
      case Repo.get_by(Site, url: attrs.url, user_id: user.id) do
        nil -> %Site{ user: user}
        site -> site
      end
      |> Site.changeset(attrs)
      |> Repo.insert_or_update
      |> update_site_vector
    rescue 
      Ecto.MultipleResultsError -> nil
    end
  end

  def update_site(%Site{} = site, attrs) do
      site
      |> Site.changeset(attrs)
      |> Site.apply_defaults
      |> Repo.update()
      |> update_site_vector
  end

  def reload_site(%Site{} = site) do
    case Site.body_changeset(site) do
      nil -> 
        nil
      changeset -> 
        Repo.update(changeset)
    end
  end

  def test() do
    Application.get_application(AuthMe.UserManager.Guardian)
    #site = get_site!(920, 13)
    #Site.remove_control_chars(site.body)
    #Site.html_tags(site.body, "head")
    #body = String.replace(site.body, "\n", "")
    #body = String.replace(body, "\t", "")
    #Regex.run(~r/<head\b(.*?)>(.*?)<\/head>/i, body)

    #Site.html_description(site.body)
  end

  def create_site(%{params: params, user: user}) do
    %Site{ user: user}
    |> Site.changeset(params)
    |> Site.reload_site
    |> Site.apply_defaults
    |> Repo.insert()
    |> update_site_vector
  end

  def delete_site(%Site{} = site) do
    Repo.delete(site)
  end

  def change_site(%Site{} = site, attrs \\ %{}) do
    Site.changeset(site, attrs)
  end

  def load_sites(site_list, user) do
    sites = site_list 
    |> Enum.filter(fn x -> is_map(x) and "url" in Map.keys(x) end)

    tasks = for site <- sites, do: Task.async(fn -> 
      Site.fetch_site(site) 
    end) 

    result = Task.yield_many(tasks, 10000) # 10 seconds
    |> Enum.map(fn { task, result } ->
      case result do
        {:ok, fetch_result } ->
          update_or_create_site(fetch_result, user)

        {:exit, reason} ->
          "exit " <> reason

        nil -> 
          Task.shutdown(task, :brutal_kill)
          "alert!"
      end
    end)
    result
  end

  def get_sites(filename) do
    stream = filename
    |> File.stream!
    |> CSV.decode(headers: true)
    |> Stream.map(fn x -> 
      case x do
       { :ok, val } -> val
       _ -> :error 
      end
    end)
    Enum.to_list(stream)
  end

  def url_keywords(url) do
    words = String.split(url, ["/", ".", "-", "_"])
    valid_words = Enum.filter(words, fn word -> Regex.match?(~r/^[a-z]{4,}$/i, word) end)
    Enum.join(valid_words, " ")
  end

  def update_site_vector({:ok, %Site{} = site}) do
    url_words = url_keywords(site.url)
    query = "UPDATE sites SET search_vector =
    setweight(to_tsvector(coalesce(sites.tags,'')), 'A') ||
    setweight(to_tsvector(coalesce(sites.title,'')), 'B') ||
    setweight(to_tsvector(coalesce(sites.body,'')), 'C') ||
    setweight(to_tsvector(coalesce($1,'')), 'D')
    where id = $2;"
    IO.puts query
    Ecto.Adapters.SQL.query!(Repo, query , [url_words, site.id])
    {:ok, site}
  end 

  def update_site_vector({:error, changeset }) do
    {:error, changeset}
  end

end
