defmodule Espy.ConnectionListener do
  @moduledoc """
  The module containing the logic for a socket listening for incoming connections.
  Once a connection has been accepted, it is passed off to the connection worker
  pool, while continuing to listen for connections.
  """
  require Logger
  use Task

  def start_link([localhost: localhost]) do
    try do
      socket = Socket.TCP.listen!(localhost.port)
      Logger.info("Connection Listener started on port #{localhost.port}")
      Task.start_link(__MODULE__, :accept_loop, [socket])
    rescue
      _ -> Logger.error("Listener could not be started on port #{localhost.port}")
    end
  end

  @spec accept_loop(Socket.t) :: any
  def accept_loop(socket) do
    connection = socket |> Socket.TCP.accept!()
    Logger.info("Connection accepted")

    contact_info = connection |> Socket.Stream.recv!() |> Jason.decode!(keys: :atoms!)
    Logger.info("Accepted contact is located at: #{contact_info.ip}:#{contact_info.port}")
    Espy.Node.add_connection(connection, contact_info)

    accept_loop(socket)
  end
end
