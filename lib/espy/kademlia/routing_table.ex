defmodule Espy.Kademlia.RoutingTable do
  use GenServer
  alias Espy.Kademlia.Bucket
  alias Espy.Kademlia.Contact

  defstruct [:localhost,
             :buckets,
             :k_size,
             :expire_time,
             :refresh_time,
             :replicate_time,
             :republish_time
            ]

  def child_spec(arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, List.wrap(arg)}
    }
  end

  def start_link(localhost, bootstrap, k) do
    GenServer.start_link(__MODULE__, [localhost: localhost, bootstrap: bootstrap, k_size: k], name: __MODULE__)
  end

  def add_contact(contact) do
    GenServer.call(__MODULE__, {:add_contact, contact})
  end

  def get_contacts() do
    GenServer.call(__MODULE__, :get_contacts)
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
    {:ok, %{localhost: localhost, buckets: %{}, k_size: k_size}}
  end

  @impl true
  def handle_call({:add_contact, contact}, _from, state) do
    {state, index} = select_or_add_bucket!(state, contact)
    bucket = state[:buckets][index]
    bucket = Bucket.add_contact(bucket, contact)
    buckets = Map.put(state[:buckets], index, bucket)
    state = Map.put(state, :buckets, buckets)

    {:reply, index, state}
  end

  @impl true
  def handle_call(:get_contacts, _from, state) do
    {:reply, get_all_contacts(state), state}
  end
end
