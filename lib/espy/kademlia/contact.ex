defmodule Espy.Kademlia.Contact do
  alias Espy.ID

  defstruct [:id, :ip, :port]

  def distance(%{id: id1}, %{id: id2}) do
    ID.distance(id1, id2)
  end
end
