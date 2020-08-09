defmodule Espy.ID do
  import Bitwise

  defstruct [:key, :time_created]

  @type t :: %__MODULE__{
    key: integer,
    time_created: DateTime.t
  }

  def new() do
    with <<key::big-integer-size(192)>> <- CryptoRand.uniform_bytes(Math.pow(2, 8), 24),

         {:ok, time} <- DateTime.now("Etc/UTC")
    do
      %__MODULE__{
        key: key,
        time_created: time
      }
    end
  end

  @spec distance(__MODULE__.t, __MODULE__.t) :: integer
  def distance(%{key: k1}, %{key: k2}) do
    k1 ^^^ k2
  end
end
