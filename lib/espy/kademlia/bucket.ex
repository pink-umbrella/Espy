defmodule Espy.Kademlia.Bucket do
  alias Espy.Kademlia.Contact

  defstruct max_size: 20, contacts: [], replacements: []
  
  defmacro contains?(%{contacts: contacts}, contact) do
    quote do: unquote(contact) in unquote(contacts)
  end

  def update(bucket = %{contacts: []}, contact) do
    %{bucket | contacts: [contact]}
  end

  def update(bucket, contact = %Contact{id: node_id})
    when contains?(bucket, contact) do
    updated = remove(bucket, contact) <> [contact]
    %{bucket | contacts: updated}
  end

  def update(bucket, contact = %Contact{node_id, ip_address, port})
    when not contains?(bucket, contact) and Map.count(bucket.nodes) == bucket.max_size do

    # Ping Top Contact
      # Wait for Response
      # If no timeout, put new contact in replcements
      # If response, move to end
  end

  def update(bucket, node = %Contact{node_id, ip_address, port})
    when not contains?(bucket, contact) and Map.count(bucket.nodes) < bucket.max_size do

    %{bucket | nodes: [bucket[:nodes] | node]}
  end

  def remove(bucket, contact) do
    List.delete(bucket.contacts, contact)
  end
end
