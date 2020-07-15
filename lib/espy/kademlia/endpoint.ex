defmodule Espy.Kademlia.Endpoint do
  use GenServer
  import Socket

  defstruct [:ip, :port, :protocol]

  @type protocol() :: :tcp | :udp | :ssl

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def send(recipient, message) do
    GenServer.call(__MODULE__, {:send, recipient, message})
  end

  def connect(endpoint, contact) do
  end

  def disconnect(endpoint, contact) do
  end

  def init(port: port, protocol: :tcp) do
    {:ok, socket: Socket.TCP.listen(port, options: [:keepalive])}
  end

  def init(port: port, protocol: :udp) do
    {:ok, socket: Socket.listen("*")}
  end

  def init([ip: ip, port: port, protocol: :ssl]) do
    {:ok, socket: Socket.listen("*")}
  end

  def handle_call({:send, recipient, message}, _from, state) do
    Socket.Stream.sendstate[:socket]
  end

  def handle_call(:accept_connection) do
  end

  def handle_call(:ack_data) do
  end

  def handle_call(:shutdown) do
  end
end
