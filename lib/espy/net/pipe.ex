defmodule Espy.Net.Pipe do
  @callback init(args :: Keyword.t()) :: atom
  @callback drain(integer, integer, any) :: any
  @callback fill(integer, integer, any) :: any
end
