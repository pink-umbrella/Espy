defmodule Espy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias Espy.Kademlia.Contact
  alias Espy.ID

  def start(_type, _args) do
    # List all child processes to be supervised
    localhost = %Contact{id: ID.new(), ip: "127.0.0.1", port: 31415}
    bootstrap = %Contact{id: ID.new(), ip: "127.0.0.1", port: 31416}
    children = [
      {Espy.Node, [localhost: localhost]},
      {Espy.Kademlia.RoutingTable, [localhost, bootstrap, 10]}
      # Starts a worker by calling: KVServer.Worker.start_link(arg)
      # {KVServer.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Espy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
