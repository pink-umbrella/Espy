defmodule Espy.Kademlia.RoutingTable do
  @moduledoc """
  A Module containing the routing logic for a Kademlia based KV store
  """
  require Logger

  use GenServer
  alias Espy.Kademlia.{Bucket, Contact}

  defstruct [:localhost,
             :buckets,
             :k_size,
             :expire_time,
             :refresh_time,
             :replicate_time,
             :republish_time
            ]
  @typedoc """
  A Kademlia Routing Table
    localhost: A Kademlia Contact
    buckets: The map of k to the k-buckets that contain contacts at k distance from localhost
    k_size: The k-bucket size to use
    expire_time: The time at which a contact is removed if it's not able to be reached
    refresh_time: The time at which the routing table tries to refresh the contents of contacts
    replicate_time: The time at which to update contacts with localhost's whole database
    republish_time: The time at which a KV Pair should be republished by it's original publisher
  """
  @type t :: %__MODULE__{
    localhost: Contact.t,
    buckets: %{required(integer) => Bucket.t},
    k_size: integer,
    expire_time: integer,
    refresh_time: integer,
    replicate_time: integer,
    republish_time: integer
  }

  def child_spec(arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, List.wrap(arg)}
    }
  end

  def start_link(localhost, bootstrap, k) do
    GenServer.start_link(__MODULE__, [localhost: localhost, bootstrap: bootstrap, k_size: k], name: __MODULE__)
  end

  @doc """
  Adds a contact to the routing table

  Returns `index` at which k-bucket the contact was added

  ## Examples

      iex> RoutingTable.add_contact(%Contact{id: id1})
      189

  """
  @spec add_contact(Contact.t) :: {atom, integer}
  def add_contact(contact) do
    GenServer.call(__MODULE__, {:add_contact, contact})
  end

  @doc """
  Gets all contacts stored in the routing table in a list

  Returns `[%Contact{}, ...]`

  ## Examples

      iex> RoutingTable.get_contacts()
      [%Contact{}, %Contact{}, %Contact{}]

  """
  @spec get_contacts() :: {atom, list(Contact.t)}
  def get_contacts() do
    GenServer.call(__MODULE__, :get_contacts)
  end

  @doc """
  Gets a requested number of contacts closest to a given contact, if there are fewer
  contacts than requested currently in the routing table, it returns the amount the
  table has.

  Returns `[%Contact{}, ..., %Contact{}]` at which k-bucket the contact was added

  ## Examples

      iex> RoutingTable.get_closest_contacts(%Contact{}, 8)
      [%Contact{}, %Contact{}, %Contact{}]

  """
  @spec get_closest_contacts(Contact.t, integer) :: {atom, list(Contact.t)}
  def get_closest_contacts(contact, count) do
    GenServer.call(__MODULE__, {:get_closest, contact, count})
  end

  defp select_or_add_bucket!(state = %{localhost: localhost, buckets: buckets, k_size: k_size}, contact) do
    with distance <- Contact.distance(localhost, contact),
         index <- trunc(Float.floor(Math.log2(distance))) do
      if not Map.has_key?(buckets, index) do
        buckets = Map.put(buckets, index, %Bucket{index: index, max_size: k_size})
        {Map.put(state, :buckets, buckets), index}
      else
        {state, index}
      end
    end
  end

  defp get_all_contacts(state) do
    get_contacts = fn bucket, acc ->
      {_, b} = bucket
      acc ++ b.contacts
    end
    Enum.reduce(state[:buckets], [], get_contacts)
  end

  @impl true
  def init([localhost: localhost, bootstrap: _bs_contact, k_size: k_size]) do
    # TODO: Load known routing table from disk storage upon hard reset
    # TODO: Do Network Search for self to bootstrap
    Logger.info("Routing table started for #{localhost.ip}:#{localhost.port} with id: #{localhost.id.key}")
    {:ok, %{localhost: localhost, buckets: %{}, k_size: k_size}}
  end

  @impl true
  def handle_call({:add_contact, contact}, _from, state) do
    {state, index} = select_or_add_bucket!(state, contact)
    bucket = state[:buckets][index]
    |> Bucket.add_contact(contact)

    buckets = Map.put(state[:buckets], index, bucket)
    state = Map.put(state, :buckets, buckets)

    {:reply, index, state}
  end

  @impl true
  def handle_call(:get_contacts, _from, state) do
    {:reply, get_all_contacts(state), state}
  end

  @impl true
  def handle_call({:get_closest, contact, count}, _from, state) do
    #Start at bucket => distnce(localhost, key)
    #Get closest from bucket
    #If result nodes > count, drop farthest to make length = count, return nodes
    #If result nodes == count, return nodes
    #If results nodes < count, recurse at distance - 1, reutrn result
    contacts = closest_start(contact, count, state)
    {:reply, contacts, state}
  end

  defp closest_start(contact, count, %{localhost: localhost, buckets: buckets}) do
    with distance <- Contact.distance(contact, localhost) do
      buckets
      |> Enum.take_while(fn {index, _bucket} -> index <= distance end)
      |> Enum.reduce_while([], fn {_index, bucket}, acc ->
        if length(acc) < count, do: {:cont, acc ++ bucket.contacts}, else: {:halt, acc}
      end)
      |> Enum.take(count)
    end
  end
end
