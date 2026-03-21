defmodule HgsBrain.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HgsBrainWeb.Telemetry,
      HgsBrain.Repo,
      {DNSCluster, query: Application.get_env(:hgs_brain, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: HgsBrain.PubSub},
      Arcana.Embedder.Local,
      # Start to serve requests, typically the last entry
      HgsBrainWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HgsBrain.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HgsBrainWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
