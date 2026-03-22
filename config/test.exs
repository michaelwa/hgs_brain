import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :hgs_brain, HgsBrain.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "hgs_brain_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :hgs_brain, HgsBrainWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "628VZP9pAY8SEceP7xkQQrVgHc2jlnEbWh58lIgt5Rs0pTj/vnRliUK1U/QHbrOn",
  server: false

# In test we don't send emails
config :hgs_brain, HgsBrain.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

config :hgs_brain, :arcana_client, HgsBrain.MockArcanaClient
config :hgs_brain, :start_embedder, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
