defmodule Espy.ConnectionWorker do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_) do
    {:ok, %{socket: nil, contact: nil}}
  end

  @impl true
  def handle_call({:connect, contact, options}, _from, state = %{socket: nil}) do
    {:ok, socket} = Socket.TCP.connect(contact.ip, contact.port, options)
    state |> Map.put(:socket, socket) |> Map.put(:contact, contact)
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
  def handle_call(:disconnect, _from, state = %{socket: socket}) do
    Socket.Stream.close(socket)
    state = Map.put(state, :socket, nil)
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
