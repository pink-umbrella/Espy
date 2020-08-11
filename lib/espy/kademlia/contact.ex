defmodule Espy.Kademlia.Contact do
  @moduledoc """
  This module contains the representation of a contact within the kademlia algorithm.
  It consists of a 192-bit id, an ip address, and a port.
  """
  alias Espy.ID

  defstruct [:id, :ip, :port]

  @typedoc """
  The type representing a Kademlia contact triple as described in the spec.
    id: 192-bit integer
    ip: string of the contact's ip
    port: port at which the contact can be contacted
  """
  @type t :: %__MODULE__{id: ID.t, ip: String.t, port: integer}

  @doc """
  Calculates the XOR distance of two contacts' IDs.

  Returns `integer`

  ## Examples

      iex> Espy.Kademlia.Contact.distance(%Contact{id: id1}, %Contact{id: id2})
      id1 ^^^ id2

  """
  @spec distance(Contact.t, Contact.t) :: integer
  def distance(%{id: id1}, %{id: id2}) do
    ID.distance(id1, id2)
  end
end
