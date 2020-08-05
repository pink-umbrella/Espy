defmodule Espy.Kademlia.Bucket do
  alias Espy.Kademlia.Contact
  alias Espy.Node
  @ping_timeout 1000
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

  def find_closest(%{contacts: contacts, max_size: max_size}, _contact, count)
    when count >= max_size, do: contacts

  def find_closest(%{contacts: contacts}, contact, count) do
    contacts
    |> Enum.sort(fn left, right ->
        Contact.distance(contact, left) <= Contact.distance(contact, right)
      end)
    |> Enum.take(count)
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
        nil when size == max_size -> async_ping(bucket, contact)
        _ -> move_contact_to_end(bucket, contact)
      end
    end

  end

  defp async_ping(bucket, contact) do
    oldest = hd(bucket[:contacts])
    Task.async(fn ->
      :poolboy.transaction(:connection_worker,
        fn pid -> GenServer.call(pid, {:ping, oldest, bucket[:index]}) end,
        @ping_timeout
      )
    end)
    Map.put(bucket, :replacements, bucket[:replacements] ++ [contact])
  end

  def remove(bucket, contact) do
    bucket = Map.put(bucket, :contacts, List.delete(bucket.contacts, contact))
    if bucket[:replacements] != [] do
      [replacement | rest] = bucket[:replacements]
      Map.put(bucket, :replacements, rest)
      |> Map.put(:contacts, bucket[:contacts] ++ [replacement])
    end
  end
end
