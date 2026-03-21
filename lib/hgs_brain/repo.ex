defmodule HgsBrain.Repo do
  use Ecto.Repo,
    otp_app: :hgs_brain,
    adapter: Ecto.Adapters.Postgres
end
