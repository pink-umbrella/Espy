defmodule Espy.Kademlia.Bucket do
  alias Espy.Kademlia.Contact
  alias Espy.Node

  defstruct max_size: 20,
            index: 0,
            contacts: [],
            replacements: [],
            lower_range: 0,
            upper_range: Math.pow(2, 192),
            depth: 0

  def add_contact(bucket, contact) do
    update(bucket, contact)
  end

  def find_contact(contacts, contact) do
    Enum.find(contacts, fn %{id: id} -> id == contact.id end)
  end

  def move_contact_to_end(bucket, contact) do
    %{bucket | contacts: remove(bucket, contact) ++ [contact]}
  end

  def update(bucket = %{contacts: []}, contact) do
    %{bucket | contacts: [contact]}
  end

  def update(bucket = %{contacts: contacts, max_size: max_size}, contact) do
    with c <- find_contact(contacts, contact), size <- length(contacts) do
      case c do
        nil when size < max_size -> %{bucket | contacts: contacts ++ [contact]}
        nil when size == max_size -> spawn ping_and_update(bucket, contact)
        _ -> move_contact_to_end(bucket, contact)
      end
    end

  end

  defp ping_and_update(bucket, contact) do
    oldest = hd(bucket[:contacts])
    case GenServer.call(Node, {:ping, oldest}) do
      :pong -> move_contact_to_end(bucket, oldest)
      _ -> %{bucket | contacts: remove(bucket, oldest) ++ contact}
    end
  end

  def remove(bucket, contact) do
    List.delete(bucket.contacts, contact)
  end
end
