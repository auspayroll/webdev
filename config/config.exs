# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :webdev2,
  ecto_repos: [Webdev2.Repo]

config :auth_me, 
  ecto_repos: [AuthMe.Repo],
  start_page: "/p/sites",
  login_page: "/auth/login"

config :webdev2, :date_format, "%d %b %Y"
config :auth_me, :date_format, "%d %b %Y"

host = System.get_env("HOST")

# Configures the endpoint
config :webdev2, Webdev2Web.Endpoint,
  url: [host: host],
  secret_key_base: "E1gNuxeX3rLorEFJFTgAAgnpyi25vXtdBx4Bkes1h4Tj0gd+HdWqZPJsJEovB201",
  render_errors: [view: Webdev2Web.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Webdev2.PubSub,
  live_view: [signing_salt: "53LIpN7c"]



# Configures the endpoint
config :auth_me, AuthMeWeb.Endpoint,
  url: [host: host],
  secret_key_base: "NI52X6NkVJwyKsWbjrnDw0dOQwTPFjx2MrB7tkmvFgVaiK7uEsnIsJ3ie/CqSVAs",
  render_errors: [view: AuthMeWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: AuthMe.PubSub,
  live_view: [signing_salt: "KqDPOGeH"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

config :auth_me, AuthMe.UserManager.Guardian, issuer: "webdev2", 
  secret_key: "LVvVsmde0q9znw+8tQBXG9YUZJMMbsNETWhpmi7dfiiH7vszMCmTIah2ecK4HEs3"

config :hackney, use_default_pool: false

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase



