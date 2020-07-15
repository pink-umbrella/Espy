defmodule Espy.Kademlia.Contact do
  import Bitwise
  
  defstruct [:id, :ip, :port]

  def distance(%{id: id1}, %{id: id2}) do
    id1^^^id2
  end
end
