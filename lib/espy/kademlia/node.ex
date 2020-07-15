defmodule Espy.Kademlia.Node do
  use GenServer

  defstruct [:endpoint, :contact, :buckets]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def add_contact(node, contact) do
    #find bucket
      #add to bucket
  end

  def create_connection(node, contact) do
  end

  def close_connection(node, contact) do
  end

  def send_data(node, contact, data) do
  end

  def init(args) do
    {:ok, }
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
