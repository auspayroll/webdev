defmodule Webdev2Web.SiteController do
  use Webdev2Web, :controller
  require Logger
  require IEx

  alias Webdev2.Web
  alias Webdev2.Web.Site

  import AuthMe, only: [current_user: 1]

  def index(conn, %{"page" => page}) do
    user = current_user(conn)
    sites = Web.list_sites(page, user.id)
    render(conn, "index.html", sites: sites)
  end

  def index(conn, _params) do
    sites = Web.list_sites("1", current_user(conn).id) #page 1
    render(conn, "index.html", sites: sites)
  end

  defmodule SearchForm do
    defstruct [:q, :page]
  end

  def search(conn, %{"search_form" => %{"q" => query_string, "page" =>  page } = params} ) do
    changeset = {%SearchForm{}, %{q: :string, page: :string}}
    |> Ecto.Changeset.cast(params, [:q, :page])
    |> Ecto.Changeset.validate_required([:q, :page])
    changeset = %{ changeset | action: :insert }
    if changeset.valid? do
      d = changeset.changes
      sites = Web.search_site(d.q, d.page, current_user(conn).id)
      render(conn, "index.html", sites: sites)
    else
      render(conn, "search.html", changeset: changeset, action: Routes.site_path(conn, :search))
    end
  end

  def search(conn, %{"search_form" => %{"q" => query_string }}) do
    search(conn, %{"search_form" => %{"q" => query_string, "page" =>  "1"}})
  end

  def search(conn, params) do
    dummy_model = {%SearchForm{}, %{q: :string}}
    changeset = Ecto.Changeset.cast(dummy_model, %{}, [:q])
    changeset = %{ changeset | action: :insert }
    render(conn, "search.html", changeset: changeset, action: Routes.site_path(conn, :search))
  end

  def reindex(conn, _params) do
    Web.reindex(current_user(conn).id)
    conn
    |> put_flash(:info, "Reindexed sites successfully.")
    |> redirect(to: Routes.site_path(conn, :index))
  end

  def new(conn, _params) do
    changeset = Web.change_site(%Site{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"site" => site_params}) do
    case Web.create_site(%{ params: site_params, user: current_user(conn)}) do
      {:ok, site} ->
        conn
        |> put_flash(:info, "Site created successfully.")
        |> redirect(to: Routes.site_path(conn, :show, site))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    site = Web.get_site!(id, current_user(conn).id)
    render(conn, "show.html", site: site)
  end

  def reload(conn, %{"id" => id}) do
    site = Web.get_site!(id, current_user(conn).id)
    case Web.reload_site(site) do
      nil -> 
        conn
        |> put_flash(:info, "Error reloading site")
        |> redirect(to: Routes.site_path(conn, :edit, site))
      _ -> 
        conn
        |> put_flash(:info, "Site reloaded successfully.")
        |> redirect(to: Routes.site_path(conn, :show, site))
    end
  end

  def view(conn, %{"id" => id}) do
    site = Web.get_site!(id, current_user(conn).id)
    html(conn, site.body)
  end

  def test(conn, _params) do
    conn = put_layout conn, false
    Logger.info("hi there")
    render(conn, "test.html")
  end

  def edit(conn, %{"id" => id}) do
    site = Web.get_site!(id, current_user(conn).id)
    changeset = Web.change_site(site)
    render(conn, "edit.html", site: site, changeset: changeset)
  end

  def update(conn, %{"id" => id, "site" => site_params}) do
    site = Web.get_site!(id, current_user(conn).id)
    case Web.update_site(site, site_params) do
      {:ok, site} ->
        conn
        |> put_flash(:info, "Site updated successfully.")
        |> redirect(to: Routes.site_path(conn, :show, site))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", site: site, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    site = Web.get_site!(id, current_user(conn))
    {:ok, _site} = Web.delete_site(site)

    conn
    |> put_flash(:info, "Site deleted successfully.")
    |> redirect(to: Routes.site_path(conn, :index))
  end

  def add_sites(conn, _params) do
    types = %{filename: :string}
    changeset = Ecto.Changeset.cast({%{}, types}, %{}, Map.keys(types))
    IO.inspect changeset
    #changeset = Ecto.Changeset.validate_required(changeset, [:filename])
    render(conn, "add_sites.html", changeset: changeset, action: Routes.site_path(conn, :add_sites))
  end

  def add_sites_post(conn, params) do
    dummy_model = {%{},%{filename: :map}}
    changeset = case params do
     %{"sites" => sites} -> 
        dummy_model
        |> Ecto.Changeset.cast(sites, [:filename])
      _ -> # sites form is empty
        dummy_model
        |> Ecto.Changeset.cast(%{}, [:filename])
    end
    changeset = Ecto.Changeset.validate_required(changeset, [:filename])
    changeset = %{changeset | action: :insert} #required so that form errors are displayed
    if changeset.valid? do
      path = changeset.changes[:filename].path
      sites = Web.get_sites(path)
      Web.load_sites(sites, current_user(conn)) #fetches and creates site records
      redirect(conn, to: Routes.site_path(conn, :index))
    else 
      render(conn, "add_sites.html", changeset: changeset, action: Routes.site_path(conn, :add_sites))
    end
  end

end
