defmodule Espy.Net.PortChoice do
  use Agent

  def start_link([min: range_start, max: range_stop]) do
    Agent.start_link(fn -> {range_start, range_stop} end, name: __MODULE__)
  end

  def take_port do
    Agent.get_and_update(__MODULE__, fn {min, max} -> {min, {min + 1, max}} end)
  end
end
