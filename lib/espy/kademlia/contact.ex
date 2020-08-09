defmodule Espy.Kademlia.Contact do
  alias Espy.ID

  defstruct [:id, :ip, :port]

  @type t :: %__MODULE__{id: integer, ip: String.t, port: integer}

  @spec distance(Contact.t, Contact.t) :: integer
  def distance(%{id: id1}, %{id: id2}) do
    ID.distance(id1, id2)
  end
end
