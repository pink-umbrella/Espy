defmodule Espy.ConnectionWorker do
  require Logger
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_) do
    Logger.info("Connection worker created")
    {:ok, %{socket: nil, contact: nil}}
  end

  @impl true
  def handle_cast({:set_connection, socket, contact}, state) do
    state |> Map.put(:socket, socket) |> Map.put(:contact, contact)
    Logger.info("Connection set with contact: #{contact.ip}:#{contact.port}")
    {:noreply, state}
  end

  @impl true
  def handle_call({:connect, contact, options}, _from, state = %{socket: nil}) do
    {:ok, socket} = Socket.TCP.connect(contact.ip, contact.port, options)
    state |> Map.put(:socket, socket) |> Map.put(:contact, contact)
    Logger.info("Connection opened with contact: #{contact.ip}:#{contact.port}")
    {:reply, :success, state}
  end

  @impl true
  def handle_call({:connect, _contact, _options}, _from, state) do
    {:reply, :already_connected, state}
  end

  @impl true
  def handle_call(:disconnect, _from, state = %{socket: nil}) do
    {:reply, :not_connected, state}
  end

  @impl true
  def handle_call(:disconnect, _from, state = %{socket: socket, contact: contact}) do
    Socket.Stream.close(socket)
    state = Map.put(state, :socket, nil)
    Logger.info("Connection disconnected with contact: #{contact.ip}:#{contact.port}")
    {:reply, :success, state}
  end

  @impl true
  def handle_call({:ping, _contact, _index}, _from, state = %{socket: nil}) do
    {:reply, {:pang, :not_connected}, state}
  end

  @impl true
  def handle_call({:ping, contact, _index}, _from, state = %{socket: socket}) do
    Socket.Stream.send(socket, [:ping, contact.id])
    {:reply, :sent, state}
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
end
