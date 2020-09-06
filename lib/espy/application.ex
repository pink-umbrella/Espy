defmodule Espy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias Espy.Kademlia.Contact
  alias Espy.ID

  def init_id do
    case Application.get_env(:id, :source) do
      :new -> ID.new()
      :dets -> create_or_get_id()
    end
  end

  def create_or_get_id do
    with dets_table <- get_dets(),
      id <- :dets.lookup(dets_table, :id) do
      case id do
        [{:id, stored_id}] -> stored_id
        _ -> :dets.insert_new(dets_table, {:id, ID.new()})
      end
      [{:id, stored_id}] = :dets.lookup(dets_table, :id)
      stored_id
    end
  end

  def get_dets do
    with {:ok, file} <- :dets.open_file(:disk_storage, [type: :set]) do
      file
    end
  end

  def start(_type, _args) do
    id = init_id()
    # List all child processes to be supervised
    localhost = %Contact{id: id, ip: "127.0.0.1", port: 31415 + :rand.uniform(50)}
    bootstrap = %Contact{id: ID.new(), ip: "127.0.0.1", port: 31416}


    children = [
      {Espy.Node, [localhost: localhost]},
      {Espy.Kademlia.RoutingTable, [localhost, bootstrap, 10]},
      {Espy.Net.Connection, %{localhost: localhost, pipeline: Espy.EndToEnd}},
      {Espy.Net.PortChoice, [min: localhost.port + 1, max: localhost.port + 1001]}
      # Starts a worker by calling: KVServer.Worker.start_link(arg)
      # {KVServer.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Espy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
