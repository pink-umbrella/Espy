defmodule Espy.Kademlia.Bucket do
  @moduledoc """
  This module is an implementation of a Kademlia k-bucket. It contains a list of
  contacts up to length k, and a list of replacement contacts if there is overflow.
  If the contacts list falls under length k, it attempts to add a contact from
  the replacement cache.
  """
  alias Espy.Kademlia.Contact
  #alias Espy.Node
  @ping_timeout 1000

  defstruct max_size: 20,
            index: 0,
            contacts: [],
            replacements: [],
            lower_range: 0,
            upper_range: Math.pow(2, 192),
            depth: 0

  @type t :: %__MODULE__{
    max_size: integer,
    index: integer,
    contacts: [Contact.t],
    replacements: [Contact.t]
  }

  @doc """
  Adds a contact to the k-bucket

  Returns `%Bucket{}` containing the contact in either contacts or replacements.

  ## Examples

      iex> Espy.Kademlia.Bucket.add_contact(%Bucket{...}, %Contact{...})
      %Espy.Kademlia.Bucket{...}

  """
  @spec add_contact(Bucket.t, Contact.t) :: Bucket.t
  def add_contact(bucket, contact) do
    update(bucket, contact)
  end

  @doc """
  Finds a contact based on a given id.

  Returns `%Contact{id: found_id, ...}`

  ## Examples

      iex> Espy.Kademlia.Bucket.find_contact_by_id(%Bucket{...}, %ID{...})
      %Espy.Kademlia.Contact{...}

  """
  @spec find_contact_by_id(list(Contact.t), Espy.ID.t) :: Contact.t | nil
  def find_contact_by_id(contacts, id) do
    Enum.find(contacts, fn %{id: current_id} -> current_id == id end)
  end

  @doc """
  Finds a desired number of contacts contained in the k-bucket with IDs close
  to a given ID

  Returns `[%Contact{...}, ...]`

  ## Examples

      iex> Espy.Kademlia.Bucket.find_contact_by_id(%Bucket{...}, %ID{...})
      %Espy.Kademlia.Contact{...}

  """
  @spec find_closest_by_id(Bucket.t, Contact.t, integer) :: list(Contact.t)
  def find_closest_by_id(%{contacts: contacts, max_size: max_size}, _contact, count)
    when count >= max_size, do: contacts

  def find_closest_by_id(%{contacts: contacts}, contact, count) do
    contacts
    |> Enum.sort(fn left, right ->
        Contact.distance(contact, left) <= Contact.distance(contact, right)
      end)
    |> Enum.take(count)
  end

  @doc """
  Finds a contact within a k-bucket, and moves that contact to the bottom of
  the k-bucket's contact list.

  Returns `%Bucket{contacts: [..., %Contact{id: requested_id}], ...}`

  ## Examples

      iex> Espy.Kademlia.Bucket.move_contact_to_end(%Bucket{...}, %Contact{id: requested_id})
      %Espy.Kademlia.Bucket{contacts: [..., %Contact(id: requested_id)], ...}

  """
  @spec move_contact_to_end(Bucket.t, Contact.t) :: Bucket.t
  def move_contact_to_end(bucket, contact) do
    bucket
    |> remove(contact)
    |> Map.update!(:contacts, &(&1 ++ [contact]))
  end

  @doc """
  Updates a given contact within the k-bucket, if no such contact is found, it is added.

  Returns `%Bucket{contacts: [..., %Contact{}]}`

  ## Examples

      iex> Espy.Kademlia.Bucket.update(%Bucket{contacts: []}, %Contact{id: id, ...})
      %Espy.Kademlia.Bucket{contacts: [%Contact{id: id}]}

      iex> Espy.Kademlia.Bucket.update(%Bucket{contacts: [%Contact{id: id}, ...]}, %Contact{id: id, ...})
      %Espy.Kademlia.Bucket{contacts: [..., %Contact{id: id}]}

  """
  @spec update(Bucket.t, Contact.t) :: Bucket.t
  def update(bucket = %{contacts: []}, contact) do
    %{bucket | contacts: [contact]}
  end

  def update(bucket = %{contacts: contacts, max_size: max_size}, contact) do
    with c <- find_contact_by_id(contacts, contact.id), size <- length(contacts) do
      case c do
        nil when size < max_size -> %{bucket | contacts: contacts ++ [contact]}
        nil when size == max_size -> async_ping(bucket, contact)
        _ -> move_contact_to_end(bucket, contact)
      end
    end
  end

  @doc """
  Removes a given contact within the k-bucket, if no such contact is found, it is ignored.
  If the bucket has at least one contact in its replacement cache, the top contact
  is removed from the cache and added to the contacts list.

  Returns `%Bucket{contacts: [..., %Contact{}]}`

  ## Examples

      iex> Espy.Kademlia.Bucket.update(%Bucket{contacts: []}, %Contact{id: id, ...})
      %Espy.Kademlia.Bucket{contacts: [%Contact{id: id}]}

      iex> Espy.Kademlia.Bucket.update(%Bucket{contacts: [%Contact{id: id}, ...]}, %Contact{id: id, ...})
      %Espy.Kademlia.Bucket{contacts: [..., %Contact{id: id}]}

  """
  @spec remove(__MODULE__.t, Contact.t) :: __MODULE__.t
  def remove(bucket, contact) do
    bucket = Map.put(bucket, :contacts, List.delete(bucket.contacts, contact))
    if bucket.replacements != [] do
      [replacement | rest] = bucket.replacements
      Map.put(bucket, :replacements, rest)
      |> Map.put(:contacts, bucket.contacts ++ [replacement])
    end
  end

  defp async_ping(bucket, contact) do
    oldest = hd(bucket.contacts)
    Task.async(fn ->
      :poolboy.transaction(:connection_worker,
        fn pid -> GenServer.call(pid, {:ping, oldest, bucket.index}) end,
        @ping_timeout
      )
    end)
    Map.put(bucket, :replacements, bucket.replacements ++ [contact])
  end
end
