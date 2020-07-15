defmodule Espy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      EspyWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Espy.PubSub},
      # Start the Endpoint (http/https)
      EspyWeb.Endpoint
      # Start a worker by calling: Espy.Worker.start_link(arg)
      # {Espy.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Espy.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    EspyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
