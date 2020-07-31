defmodule Espy.Node do
  use GenServer
  alias Espy.Kademlia.RoutingTable

  defstruct [:localhost]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def create_connection(node, contact) do
  end

  def close_connection(node, contact) do
  end

  def send_data(node, contact, data) do
  end

  @impl true
  def init(localhost: localhost) do
    {:ok, %{localhost: localhost}}
  end

  def handle_call(:ping, contact) do

  end
  
  def handle_call(:add_contact) do
  end

  def handle_call(:create_connection) do
  end

  def handle_call(:close_connection) do
  end

  def handle_call(:send_data) do
  end
end
