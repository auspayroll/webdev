defmodule Webdev2Web.Router do
  use Webdev2Web, :router
  #import Plug.Conn

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :auth do
    plug AuthMe.UserManager.Pipeline
  end

  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/auth", AuthMeWeb do
  #  match :*, "/", Router, :get
    match :*, "/:any", Router, :any
  end

  scope "/", Webdev2Web do
    pipe_through [:browser]
    get "/", PageController, :index
  end

  scope "/p", Webdev2Web do
    pipe_through [:browser, :auth, :ensure_auth]
    get "/view/:id", SiteController, :view 
    get "/reload/:id", SiteController, :reload
    #get "/sites/:id", SiteController, :pag_index
    resources "/sites", SiteController
    get "/addsites", SiteController, :add_sites
    post "/addsites", SiteController, :add_sites_post
    get "/search", SiteController, :search
    post "/search", SiteController, :search
    get "/reindex", SiteController, :reindex
  end

  scope "/", Webdev2Web do
    pipe_through [:browser] #, :ensure_auth]
    get "/test", SiteController, :test
  end

  #match :*, "/auth/:any", AuthMeWeb.Router, :any


  # Other scopes may use custom stacks.
  # scope "/api", Webdev2Web do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  #if Mix.env() in [:dev, :test] do
  #  import Phoenix.LiveDashboard.Router

  #  scope "/" do
  #    pipe_through :browser
  #    live_dashboard "/dashboard", metrics: Webdev2Web.Telemetry
  #  end
  #end
end
