defmodule Espy.Node do
  require Logger
  use GenServer
  alias Espy.Kademlia.{RoutingTable, Contact}
  alias Espy.Connection

  defstruct [:localhost, :connections]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec add_connection(Socket.t, Contact.t) :: atom
  def add_connection(socket, contact) do
    GenServer.cast(__MODULE__, {:add_connection, socket, contact})
  end

  @spec create_connection(Contact.t) :: atom
  def create_connection(contact) do
    GenServer.cast(__MODULE__, {:create_connection, contact})
  end

  @spec close_connection(Contact.t) :: atom
  def close_connection(contact) do
    GenServer.cast(__MODULE__, {:close_connection, contact})
  end

  @spec ping(Contact.t) :: atom
  def ping(contact) do
    GenServer.call(__MODULE__, {:ping, contact})
  end

  @impl true
  def init(localhost: localhost) do
    Logger.info("Node started with localhost: #{localhost.ip}:#{localhost.port}")
    {:ok, %{localhost: localhost, connections: %{}}}
  end

  @impl true
  def handle_cast({:add_connection, socket, contact}, state) do
    with worker <- ConnectionSup.checkout() do
      ConnectionWorker.set_connection(worker, socket, contact)
      {:noreply, state |> store_contact_worker_pair(contact, worker)}
    end
  end

  @impl true
  def handle_cast({:create_connection, contact}, state = %{localhost: localhost}) do
    with worker <- ConnectionSup.checkout() do
      ConnectionWorker.connect(worker, localhost, contact)
      {:noreply, state |> store_contact_worker_pair(contact, worker)}
    end
  end

  @impl true
  def handle_cast({:close_connection, contact}, state = %{connections: conns}) do
    with worker <- Map.get(conns, contact) do
      ConnectionWorker.disconnect(worker)
    end

    conns = Map.delete(conns, contact)

    {:noreply, state |> Map.put(:connections, conns)}
  end

  @impl true
  def handle_call({:ping, _contact}, _from, state = %{socket: nil}) do
    {:reply, {:pang, :not_connected}, state}
  end

  @impl true
  def handle_call({:ping, ping_contact}, _from, state) do
    with worker <- Map.get(state.connections, ping_contact),
         :sent <- Task.async(ConnectionWorker, :ping, [worker, ping_contact])
                 |> Task.await do

      Logger.info("Successfully sent a ping to #{ping_contact}")

      {:reply, :sent, state}
    end
  end

  @impl true
  def handle_call({:find_node, _id}, _from, state = %{socket: nil}) do
    {:reply, {:fail, :not_connected}, state}
  end

  @impl true
  def handle_call({:find_node, id}, _from, state = %{socket: socket}) do
    Socket.Stream.send(socket, [:find_node, id])
    {:reply, :sent, state}
  end

  @impl true
  def handle_call({:find_value, _key}, _from, state = %{socket: nil}) do
    {:reply, {:fail, :not_connected}, state}
  end

  @impl true
  def handle_call({:find_value, key}, _from, state = %{socket: socket}) do
    Socket.Stream.send(socket, [:find_value, key])
    {:reply, :sent, state}
  end

  @impl true
  def handle_call({:store_value, _value}, _from, state = %{socket: nil}) do
    {:reply, {:fail, :not_connected}, state}
  end

  @impl true
  def handle_call({:store_value, value}, _from, state = %{socket: socket}) do
    Socket.Stream.send(socket, [:find_value, value])
    {:reply, :sent, state}
  end

  defp store_contact_worker_pair(node, contact, worker) do
    connections = node.connections |> Map.put(contact, worker)
    node |> Map.put(:connections, connections)
  end
end
