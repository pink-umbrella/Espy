defmodule Espy.Node do
  require Logger
  use GenServer
  alias Espy.Kademlia.{RoutingTable, Contact}
  alias Espy.ConnectionSup

  defstruct [:localhost, :connections]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec add_connection(Socket.t, Contact.t) :: atom
  def add_connection(socket, contact) do
    GenServer.cast(__MODULE__, {:add_connection, socket, contact})
  end

  def create_connection(node, contact) do
  end

  def close_connection(node, contact) do
  end

  def send_data(node, contact, data) do
  end

  @impl true
  def init(localhost: localhost) do
    Logger.info("Node started with localhost: #{localhost.ip}:#{localhost.port}")
    {:ok, %{localhost: localhost, connections: []}}
  end

  @impl true
  def handle_cast({:add_connection, socket, contact}, state = %{connections: connections}) do
    worker = ConnectionSup.checkout()
    GenServer.cast(worker, {:set_connection, socket, contact})
    state = state |> Map.put(:connections, connections ++ [worker])
    {:noreply, state}
  end

  @impl true
  def handle_call(:create_connection, _from, state) do
    {:reply, nil, state}
  end

  @impl true
  def handle_call(:close_connection, _from, state) do
    {:reply, nil, state}
  end

  @impl true
  def handle_call({:ping, _contact}, _from, state) do
    {:reply, nil, state}
  end

  @impl true
  def handle_call(:send_data, _from, state) do
    {:reply, nil, state}
  end
end
