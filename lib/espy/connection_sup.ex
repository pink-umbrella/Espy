defmodule Espy.ConnectionSup do
  require Logger
  
  defp poolboy_config do
  [
    name: {:local, :connection_worker},
    worker_module: Espy.ConnectionWorker,
    size: 24,
    max_overflow: 5
  ]
  end

  def child_spec(opts) do
  %{
    id: __MODULE__,
    start: {__MODULE__, :start_link, [opts]},
    type: :worker,
    restart: :permanent,
    shutdown: 500
  }
  end

  def start_link(args) do
    children = [
      :poolboy.child_spec(:connection_worker, poolboy_config()),
      {Espy.ConnectionListener, localhost: args[:localhost]}
    ]

    Supervisor.start_link(children, [strategy: :one_for_one])
  end

  def checkout() do
    Logger.info("Checking out connection worker")
    :poolboy.checkout(:connection_worker)
  end

  def checkin(worker) do
    Logger.info("Checking in worker")
    :poolboy.checkin(:connection_worker, worker)
  end
end
