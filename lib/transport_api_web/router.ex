defmodule TransportApiWeb.Router do
  use TransportApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TransportApiWeb do
    pipe_through :api
    get "/stops", StopController, :index
    get "/routes", RouteController, :index
    get "/feeds/:date", FeedController, :download
  end

  scope "/api" do
    pipe_through :api
    forward "/graphql", Absinthe.Plug, schema: TransportApiWeb.Schema
  end

  if Application.compile_env(:transport_api, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: TransportApiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
