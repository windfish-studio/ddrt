defmodule Drtree do
  use GenServer

  defstruct metadata: nil,
            tree: nil,
            listeners: [],
            crdt: nil

  @moduledoc """
  This is the API module of the elixir r-tree implementation where you can do the basic actions.

  ## Actions provided:
      - insert/2
      - query/2
      - query/3
      - delete/2
      - update_leaf/3
      - execute/1

  ## Important points:

    If you want to use the `%{database: true}` option, you have to get dev dependencies.

    Every `id` inserted must be uniq, `Drtree` won't crush the duplicated `id`.

    Every bounding box should look like this: `[{xm,xM},{ym,yM}]`
    - `xm`: minimum x value
    - `xM`: maximum x value
    - `ym`: minimum y value
    - `yM`: maximum y value
  """
  @type coord_range :: {number(),number()}
  @type bounding_box :: list(coord_range())

  @doc """
  Insert the given `leaf` to the given `tree`.

  Returns `map()`

  ## Parameters

    - `tree`: Map that represents the r-tree structure
    - `{id, bounding box}` = `leaf`: Tuple with spatial data to insert in the r-tree.

  ## Examples

      iex> t = Drtree.new
      iex> t = t |> Drtree.insert({0,[{1,2},{5,6}]})
      %{
        0 => :leaf,
        43143342109176739 => [0],
        :metadata => %{...},
        :parents => %{0 => 43143342109176739},
        :ticket => [19125803434255161 | 82545666616502197],
        'root' => 43143342109176739
      }

  """
  @spec rinsert(map(),tuple())::map()
  defdelegate rinsert(tree,leaf), to: ElixirRtree
  @doc """
  Find all leafs that match with the `box` query.

  Returns `list()`

  ## Parameters

    - `tree`: Map that represents the r-tree structure.
    - `box`: Bounding box `[{x_min,x_max},{y_min,y_max}]`.

  ## Examples

      iex> t = Drtree.new
      iex> t = t |> Drtree.insert({0,[{10,20},{0,20}]})
      iex> t |> Drtree.query([{-100,100},{-50,50}])
      [0]
      iex> t |> Drtree.query([{-100,100},{30,50}])
      []
      iex> t |> Drtree.query([{15,100},{10,50}])
      [0]
      iex> t |> Drtree.query([{15,16},{10,11}])
      [0]

  """
  @spec bquery(map(),bounding_box)::list(integer())
  defdelegate bquery(tree,box), to: ElixirRtree
  @doc """
  Find all nodes that match with the `box` query at the given `depth` of the r-tree.

  Returns `list()`

  ## Parameters

    - `tree`: Map that represents the r-tree structure.
    - `box`: Bounding box `[{x_min,x_max},{y_min,y_max}]`.
    - `depth`: Integer that define the query r-tree depth limit. Note: 0 is root node.
  """
  @spec bquery(map(),bounding_box,integer())::list(integer())
  defdelegate bquery(tree,box,depth), to: ElixirRtree
  @doc """
  Delete the leaf with the given `id`.

  Returns `map()`

  ## Parameters

    - `tree`: Map that represents the r-tree structure.
    - `id`:  Id of the required leaf to erase.

  ## Examples

      iex> t = Drtree.new
      %{
        43143342109176739 => [],
        :metadata => %{...},
        :parents => %{},
        :ticket => [19125803434255161 | 82545666616502197],
        'root' => 43143342109176739
      }

      iex> t = t |> Drtree.insert({0,[{10,20},{0,20}]})
      %{
        0 => :leaf,
        43143342109176739 => [0],
        :metadata => %{...},
        :parents => %{0 => 43143342109176739},
        :ticket => [19125803434255161 | 82545666616502197],
        'root' => 43143342109176739
      }

      iex> t = t |> Drtree.delete(0)
      %{
        43143342109176739 => [],
        :metadata => %{...},
        :parents => %{},
        :ticket => [19125803434255161 | 82545666616502197],
        'root' => 43143342109176739
      }
  """
  @spec rdelete(map(),any())::map()
  defdelegate rdelete(tree,id), to: ElixirRtree
  @doc """
  Update the leaf bounding box with the given `id`.

  Returns `map()`

  ## Parameters

    - `tree`: Map that represents the r-tree structure.
    - `id`: Id of the required leaf to be updated.
    - `update`: Bounding box update. `{old_box,new_box}` | `{new_box}`

  ## Examples

      iex> t = Drtree.new
      iex> t = t |> Drtree.insert({0,[{10,20},{0,20}]})
      %{
        ...
      }

      iex> t = t |> Drtree.update_leaf(0,[{11,21},{1,21}])
      %{
        ...
      }

      iex> t = t |> Drtree.update_leaf(0,{[{10,20},{0,20}],[{11,21},{1,21}]})
      %{
        ...
      }
  """
  @spec rupdate_leaf(map(),any(),{bounding_box,bounding_box} | {bounding_box})::map()
  defdelegate rupdate_leaf(tree,id,update), to: ElixirRtree


  @opt_values %{
    type: [Map,MerkleMap],
    mode: [:standalone, :distributed]
  }

  @defopts %{
    width: 6,
    type: Map,
    mode: :standalone,
    verbose: false, #TODO: This crazy american prefers Logger comparison than the verbose flag ùwú
    seed: 0
  }


  def new(opts \\ @defopts,name \\ __MODULE__)when is_map(opts)do
    GenServer.call(name,{:new,opts})
  end

  def insert(_a,name \\ __MODULE__)
  def insert(leafs,name)when is_list(leafs)do
    GenServer.call(name,{:bulk_insert,leafs},:infinity)
  end
  def insert(leaf, name)do
    GenServer.call(name,{:insert,leaf},:infinity)
  end

  def query(box,name \\ __MODULE__)do
    GenServer.call(name,{:query,box})
  end
  def pquery(box,depth,name \\ __MODULE__)do
    GenServer.call(name,{:query_depth,{box,depth}})
  end

  def delete(_a,name \\ __MODULE__)
  def delete(ids, name)when is_list(ids)do
    GenServer.call(name,{:bulk_delete,ids},:infinity)
  end
  def delete(id, name)do
    GenServer.call(name,{:delete,id})
  end

  def updates(updates,name \\ __MODULE__)when is_list(updates)do
    GenServer.call(name,{:bulk_update,updates},:infinity)
  end
  def update(id,update,name \\ __MODULE__)do
    GenServer.call(name,{:update,{id,update}})
  end

  def metadata(name \\ __MODULE__)
  def metadata(name)do
    GenServer.call(name,:metadata)
  end

  def tree(name \\ __MODULE__)
  def tree(name)do
    GenServer.call(name,:tree)
  end

  def merge_diffs(_a,name \\ __MODULE__)
  def merge_diffs(diffs,name)do
    send(name,{:merge_diff,diffs})
  end

  defp is_distributed?(state)do
    state.metadata[:params][:mode] == :distributed
  end

  defp constraints()do
    %{
      width: fn v -> v > 0 end,
      type: fn v -> v in (@opt_values |> Map.get(:type)) end,
      mode: fn v -> v in (@opt_values |> Map.get(:mode)) end,
      verbose: fn v -> is_boolean(v) end,
      seed: fn v -> is_integer(v) end
    }
  end

  defp filter_conf(opts)do
    new_opts = if opts[:mode] == :distributed, do: Map.put(opts,:type,MerkleMap), else: opts
    good_keys = new_opts |> Map.keys |> Enum.filter(fn k -> constraints() |> Map.has_key?(k) and constraints()[k].(new_opts[k]) end)
    good_keys |> Enum.reduce(@defopts, fn k,acc ->
      acc |> Map.put(k,new_opts[k])
    end)
  end

  defp get_rbundle(state)do
    meta = state.metadata
    params = meta.params
    %{
      tree: state.tree,
      width: params[:width],
      verbose: params[:verbose],
      type: params[:type],
      seeding: meta[:seeding]
    }
  end

  def start_link(opts)do
    name = if opts[:name], do: opts[:name], else: __MODULE__
    GenServer.start_link(__MODULE__,opts, name: name)
  end

  @impl true
  def init(opts)do
    conf = filter_conf(opts[:conf])
    {t,meta} = ElixirRtree.new(conf)
    listeners = Node.list
    t = if %{metadata: meta} |> is_distributed? do
      DeltaCrdt.set_neighbours(opts[:crdt],Enum.map(Node.list, fn x -> {opts[:crdt],x} end))
      :timer.sleep(10)
      crdt_value = DeltaCrdt.read(opts[:crdt])
      :net_kernel.monitor_nodes(true, node_type: :visible)
      if crdt_value != %{}, do: reconstruct_from_crdt(crdt_value,t), else: t
    else
      t
    end

    {:ok, %__MODULE__{metadata: meta, tree: t, listeners: listeners, crdt: opts[:crdt]}}
  end

  @impl true
  def handle_call({:new,config},_from,state)do
    conf = config |> filter_conf
    {t,meta} = ElixirRtree.new(conf)
    {:reply, {:ok,t} , %__MODULE__{state | metadata: meta, tree: t}}
  end

  @impl true
  def handle_call({:insert,leaf},_from,state)do
    r = {_atom,t} = case state.tree do
      nil -> {:badtree,state.tree}
      _ -> {:ok,get_rbundle(state) |> rinsert(leaf)}
    end

    if is_distributed?(state) do
      diffs = tree_diffs(state.tree,t)
      sync_crdt(diffs,state.crdt)
    end

    {:reply, r , %__MODULE__{state | tree: t}}
  end

  @impl true
  def handle_call({:bulk_insert,leafs},_from,state)do
    r = {_atom,t} = case state.tree do
      nil -> {:badtree,state.tree}
      _ ->
        final_rbundle = leafs |> Enum.reduce(get_rbundle(state), fn l,acc ->
          %{acc | tree: acc |> rinsert(l)}
        end)
        {:ok,final_rbundle.tree}
    end

    if is_distributed?(state) do
      diffs = tree_diffs(state.tree,t)
      sync_crdt(diffs,state.crdt)
    end

    {:reply, r , %__MODULE__{state | tree: t}}
  end

  @impl true
  def handle_call({:query,box},_from,state)do
    r = {_atom,_t} = case state.tree do
      nil -> {:badtree, state.tree}
      _ -> {:ok, get_rbundle(state) |> bquery(box)}
    end
    {:reply, r , state}
  end

  @impl true
  def handle_call({:query_depth,{box,depth}},_from,state)do
    r = {_atom,_t} = case state.tree do
      nil -> {:badtree,state.tree}
      _ -> {:ok,get_rbundle(state) |> bquery(box,depth)}
    end
    {:reply, r , state}
  end

  @impl true
  def handle_call({:delete,id},_from,state)do
    r = {_atom,t} = case state.tree do
      nil -> {:badtree,state.tree}
      _ -> {:ok,get_rbundle(state) |> rdelete(id)}
    end

    if is_distributed?(state) do
      diffs = tree_diffs(state.tree,t)
      sync_crdt(diffs,state.crdt)
    end

    {:reply, r , %__MODULE__{state | tree: t}}
  end

  @impl true
  def handle_call({:bulk_delete,ids},_from,state)do
    r = {_atom,t} = case state.tree do
      nil -> {:badtree,state.tree}
      _ ->
        final_rbundle = ids |> Enum.reduce(get_rbundle(state), fn id,acc ->
          %{acc | tree: acc |> rdelete(id)}
        end)
        {:ok,final_rbundle.tree}
    end

    if is_distributed?(state) do
      diffs = tree_diffs(state.tree,t)
      sync_crdt(diffs,state.crdt)
    end

    {:reply, r , %__MODULE__{state | tree: t}}
  end

  @impl true
  def handle_call({:update,{id,update}},_from,state)do
    r = {_atom,t} = case state.tree do
      nil -> {:badtree,state.tree}
      _ -> {:ok,get_rbundle(state) |> rupdate_leaf(id,update)}
    end

    if is_distributed?(state) do
      diffs = tree_diffs(state.tree,t)
      sync_crdt(diffs,state.crdt)
    end

    {:reply, r , %__MODULE__{state | tree: t}}
  end

  @impl true
  def handle_call({:bulk_update,updates},_from,state)do
    r = {_atom,t} = case state.tree do
      nil -> {:badtree,state.tree}
      _ ->
        final_rbundle = updates |> Enum.reduce(get_rbundle(state), fn {id,update} = _u,acc ->
          %{acc | tree: acc |> rupdate_leaf(id,update)}
        end)
        {:ok,final_rbundle.tree}
    end

    if is_distributed?(state) do
      diffs = tree_diffs(state.tree,t)
      sync_crdt(diffs,state.crdt)
    end

    {:reply, r , %__MODULE__{state | tree: t}}
  end

  @impl true
  def handle_call(:metadata,_from,state)do
    {:reply, state.metadata , state}
  end

  @impl true
  def handle_call(:tree,_from,state)do
    {:reply, state.tree , state}
  end

  # Distributed things

  @impl true
  def handle_info({:merge_diff,diff},state)do
   new_tree = diff |> Enum.reduce(state.tree, fn x,acc ->
      case x do
        {:add,k,v} -> acc |> MerkleMap.put(k,v)
        {:remove,k} -> acc |> MerkleMap.delete(k)
      end
    end)

    {:noreply , %__MODULE__{state | tree: new_tree}}
  end

  def handle_info({:nodeup, _node, _opts}, state) do
    DeltaCrdt.set_neighbours(state.crdt,Enum.map(Node.list, fn x -> {state.crdt,x} end))
    {:noreply, %__MODULE__{state | listeners: Node.list}}
  end

  def handle_info({:nodedown, _node, _opts}, state) do
    DeltaCrdt.set_neighbours(state.crdt,Enum.map(Node.list, fn x -> {state.crdt,x} end))
    {:noreply, %__MODULE__{state | listeners: Node.list}}
  end

  def sync_crdt(diffs,crdt)when length(diffs) > 0 do
    diffs |> Enum.each(fn {k,v} ->
      if v do
        DeltaCrdt.mutate(crdt, :add, [k, v])
      else
        DeltaCrdt.mutate(crdt, :remove, [k])
      end
    end)
  end

  def sync_crdt(_diffs,_crdt)do
  end

  def reconstruct_from_crdt(map,t)do
    map |> Enum.reduce(t,fn {x,y},acc ->
      acc |> MerkleMap.put(x,y)
    end)
  end

  def tree_diffs(old_tree,new_tree)do
    {:ok,keys} = MerkleMap.diff_keys(old_tree |> MerkleMap.update_hashes,new_tree |> MerkleMap.update_hashes)
    keys |> Enum.map(fn x -> {x,new_tree |> MerkleMap.get(x)} end)
  end

end
