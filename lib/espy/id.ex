defmodule Espy.ID do
  @moduledoc """
  This module consists of a 192 bit key as an integer, and the time the id was issued.
  """
  import Bitwise

  @derive Jason.Encoder
  defstruct [:key, :time_created]

  @type t :: %__MODULE__{
    key: integer,
    time_created: DateTime.t
  }

  @doc """
  Issues a new randomly generated ID recording the time of issuance.

  Returns `%ID{}`.

  ## Examples

      iex> Espy.ID.new()
      %Espy.ID{key: ...3534, time_created: ~U[2020-08-10 02:32:22.097046Z]}

  """
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

  @doc """
  Returns the XOR distance between two IDs, as specified in the Kademlia whitepaper,
  located [here](http://www.scs.stanford.edu/~dm/home/papers/kpos.pdf).

  Returns `integer \#192 bits`
  """
  @spec distance(ID.t, ID.t) :: integer
  def distance(%{key: k1}, %{key: k2}) do
    k1 ^^^ k2
  end
end
