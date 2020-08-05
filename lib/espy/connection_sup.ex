defmodule Espy.ConnectionSup do
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

  def start_link(_args) do
    children = [
      :poolboy.child_spec(:connection_worker, poolboy_config())
    ]

    Supervisor.start_link(children, [strategy: :one_for_one])
  end
end
