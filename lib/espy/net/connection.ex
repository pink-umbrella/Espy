defmodule Espy.Net.Connection do
  @moduledoc """
  The module containing the logic for a socket listening for incoming connections.
  Once a connection has been accepted, it is passed off to the connection worker
  pool, while continuing to listen for connections.
  """
  require Logger
  use GenServer
  alias Socket.{UDP, Datagram}
  #alias Espy.Net.Pipeline

  def send(datatype, data, contact) do
    GenServer.cast(__MODULE__, {:send, datatype, data, contact})
  end

  def connect(contact) do
    send(:connect, contact, contact)
  end

  def ping(contact) do
    send(:ping, contact, contact)
  end

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(arg_map) do
    with pipeline <- arg_map[:pipeline],
         localhost <- arg_map[:localhost],
         opts <- arg_map[:opts] || [] do
      apply(pipeline, :init, opts)

      socket = UDP.open!(localhost.port, [mode: :active, as: :binary])
      UDP.process!(socket, self())

      Logger.info("Connection service started")

      {private, public} = Curve25519.generate_key_pair()

      {:ok, %{socket: socket,
              localhost: localhost,
              pipeline: pipeline,
              connections: [],
              public_key: public,
              private_key: private}} #TODO: Do better
    end
  end

  @impl true
  def handle_cast({:send, :connect, _, contact},
    state = %{socket: socket, public_key: pb_key}) do
    Logger.info("Attempting to connect to #{contact}")

    Datagram.send!(socket, Jason.encode!([:connect, [public_key: pb_key]]), {contact.ip, contact.port})

    {:noreply, state |> Map.update!(:connections, fn conns -> conns ++ [contact] end)}
  end

  @impl true
  def handle_cast({:send, datatype, data, contact}, state = %{socket: socket, pipeline: pipeline}) do
    Logger.info("Sending a #{datatype} message to #{contact}")

    packet = apply(pipeline, :fill, [contact.ip, contact.port, [datatype, data]])

    Datagram.send!(socket, packet, {contact.ip, contact.port})
    {:noreply, state}
  end

  @impl true
  def handle_info({:udp, _socket, from_ip, from_port, packet}, state = %{pipeline: pipeline}) do
    Logger.info("Recieved a UDP message from: #{Socket.Address.to_string(from_ip)}:#{from_port}")

    apply(pipeline, :drain, [from_ip, from_port, packet])
    {:noreply, state}
  end
end
