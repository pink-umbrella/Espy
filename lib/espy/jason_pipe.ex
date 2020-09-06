defmodule Espy.JasonPipe do
  @behaviour Espy.Net.Pipe

  @impl true
  def init(_args) do
    :ok
  end

  @impl true
  def drain(ip, port, data) do
    [ip, port, Jason.encode!(data)]
  end

  @impl true
  def fill(ip, port, data) do
    [ip, port, Jason.decode!(data)]
  end
end
