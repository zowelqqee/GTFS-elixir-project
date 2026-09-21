defmodule TransportApi.Application do

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TransportApiWeb.Telemetry,
      TransportApi.Repo,
      TransportApi.GTFS.FeedWorker,
      {DNSCluster, query: Application.get_env(:transport_api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TransportApi.PubSub},
      TransportApiWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: TransportApi.Supervisor]
    Supervisor.start_link(children, opts)
  end


  @impl true
  def config_change(changed, _new, removed) do
    TransportApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
