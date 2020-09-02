# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
use Mix.Config
database_host = System.get_env("DATABASE_HOST") || 
    raise """
    environment variable DATABASE_HOST is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

database_name = System.get_env("DATABASE") || 
  raise """
  environment variable DATABASE is missing.
  For example: ecto://USER:PASS@HOST/DATABASE
  """

database_password = System.get_env("DATABASE_PASSWORD") || 
  raise """
  environment variable DATABASE_PASSWORD is missing.
  For example: ecto://USER:PASS@HOST/DATABASE
  """

database_url = "ecto://postgres:"<> database_password <> "@"<>database_host<>"/"<>database_name
  #System.get_env("DATABASE_URL") ||


config :webdev2, Webdev2.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")


config :auth_me, AuthMe.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :webdev2, Webdev2Web.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
config :webdev2, Webdev2Web.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
