defmodule Drtree do
  use GenServer

  defstruct metadata: nil,
            tree: nil

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
  @spec insert(map(),tuple())::map()
  defdelegate insert(tree,leaf), to: ElixirRtree
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
  @spec delete(map(),any())::map()
  defdelegate delete(tree,id), to: ElixirRtree
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
  @spec update_leaf(map(),any(),{bounding_box,bounding_box} | {bounding_box})::map()
  defdelegate update_leaf(tree,id,update), to: ElixirRtree
  @doc """
  Execute the `tree` RAM resources.

  Returns `boolean()`

  ## Parameters

    - `tree`: Map that represents the r-tree structure.

  ## Examples

      iex> t = Drtree.new
      iex> t |> Drtree.execute
      true
  """
  @spec execute(map())::boolean()
  defdelegate execute(tree), to: ElixirRtree


  @opt_values %{
    type: [Map,MerkleMap],
    access: [:protected, :public, :private]
  }

  @defopts %{
    width: 6,
    type: Map,
    verbose: false, #TODO: This crazy american prefers Logger comparison than the verbose flag ùwú
    database: false,
    access: :protected,
    seed: 0
  }

  @doc """
  Create a new r-tree with default parameters.

  Returns `map()`

  ## Examples

      iex> Drtree.new
      %{
        43143342109176739 => [],
        :metadata => %{...},
        :parents => %{},
        :ticket => [19125803434255161 | 82545666616502197],
        'root' => 43143342109176739
      }
  """
  @spec new()::map()
  def new()do
    GenServer.call(Drtree,{:new,@defopts})
  end

  @doc """
  Create a new r-tree with the given `opts`.

  Returns `map()`

  ## Parameters

    - `width`: the node childs limit (the amplitude)
    - `database`: the boolean flag that set the r-tree to a dgraph database (performance -825%)
    - `verbose`: the boolean flag that set the logger output (performance -10%)
    - `access`: the access permissions to the tree `[:public, :protected, :private]`
    - `seed`: the seed for the r-tree middle nodes uuid

  ## Examples

      iex> Drtree.new(%{access: :public, width: 8})
      %{
        43143342109176739 => [],
        :metadata => %{
          dgraph: nil,
          ets_table: #Reference<0.2361800908.1666318340.51022>,
          params: %{
            access: :public,
            database: false,
            seed: 0,
            type: :standalone,
            verbose: false,
            width: 8
          },
          seeding: %{
            ...
          }
        },
        :parents => %{},
        :ticket => [19125803434255161 | 82545666616502197],
        'root' => 43143342109176739
      }
  """
  @spec new(%{})::map()
  def new(opts)when is_map(opts)do
    GenServer.call(Drtree,{:new,opts})
  end

  def insert(leafs)when is_list(leafs)do
    GenServer.call(Drtree,{:bulk_insert,leafs},:infinity)
  end

  def insert(leaf)do
    GenServer.call(Drtree,{:insert,leaf})
  end

  def query(box)do
    GenServer.call(Drtree,{:query,box})
  end

  def query(box,depth)do
    GenServer.call(Drtree,{:query_depth,{box,depth}})
  end

  def delete(ids)when is_list(ids)do
    GenServer.call(Drtree,{:bulk_delete,ids},:infinity)
  end

  def delete(id)do
    GenServer.call(Drtree,{:delete,id})
  end

  def update(updates)when is_list(updates)do
    GenServer.call(Drtree,{:bulk_update,updates},:infinity)
  end

  def update(id,update)do
    GenServer.call(Drtree,{:update,{id,update}})
  end

  def execute()do
    GenServer.call(Drtree,:execute)
  end

  def metadata()do
    GenServer.call(Drtree,:metadata)
  end

  def tree()do
    GenServer.call(Drtree,:tree)
  end

  @doc false
  def default_params()do
    @defopts
  end

  defp constraints()do
    %{
      width: fn v -> v > 0 end,
      type: fn v -> v in (@opt_values |> Map.get(:type)) end,
      verbose: fn v -> is_boolean(v) end,
      database: fn v -> is_boolean(v) end,
      access: fn v -> v in (@opt_values |> Map.get(:access)) end,
      seed: fn v -> is_integer(v) end
    }
  end

  defp filter_conf(opts)do
    good_keys = opts |> Map.keys |> Enum.filter(fn k -> constraints() |> Map.has_key?(k) and constraints()[k].(opts[k]) end)
    good_keys |> Enum.reduce(@defopts, fn k,acc ->
      acc |> Map.put(k,opts[k])
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
      ets: meta.ets_table,
      db: meta.dgraph,
      seeding: meta[:seeding]
    }
  end

  def start_link(opts)do
    GenServer.start_link(__MODULE__,opts, name: __MODULE__)
  end


  @impl true
  def init(opts)do
    conf = filter_conf(opts)
    {t,meta} = ElixirRtree.new(conf)
    {:ok, %__MODULE__{metadata: meta, tree: t}}
  end

  @impl true
  def handle_call({:new,config},_from,state)do
    if state.tree, do: get_rbundle(state) |> execute
    conf = config |> filter_conf
    {t,meta} = ElixirRtree.new(conf)
    {:reply, {:ok,t} , %__MODULE__{metadata: meta, tree: t}}
  end

  @impl true
  def handle_call({:insert,leaf},_from,state)do
    r = {_atom,t} = case state.tree do
      nil -> {:badtree,state.tree}
      _ -> {:ok,get_rbundle(state) |> insert(leaf)}
    end
    {:reply, r , %__MODULE__{state | tree: t}}
  end

  @impl true
  def handle_call({:bulk_insert,leafs},_from,state)do
    r = {_atom,t} = case state.tree do
      nil -> {:badtree,state.tree}
      _ ->
        final_rbundle = leafs |> Enum.reduce(get_rbundle(state), fn l,acc ->
          %{acc | tree: acc |> insert(l)}
        end)
        {:ok,final_rbundle.tree}
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
      _ -> {:ok,get_rbundle(state) |> delete(id)}
    end
    {:reply, r , %__MODULE__{state | tree: t}}
  end

  @impl true
  def handle_call({:bulk_delete,ids},_from,state)do
    r = {_atom,t} = case state.tree do
      nil -> {:badtree,state.tree}
      _ ->
        final_rbundle = ids |> Enum.reduce(get_rbundle(state), fn id,acc ->
          %{acc | tree: acc |> delete(id)}
        end)
        {:ok,final_rbundle.tree}
    end
    {:reply, r , %__MODULE__{state | tree: t}}
  end

  @impl true
  def handle_call({:update,{id,update}},_from,state)do
    r = {_atom,t} = case state.tree do
      nil -> {:badtree,state.tree}
      _ -> {:ok,get_rbundle(state) |> update_leaf(id,update)}
    end

    {:reply, r , %__MODULE__{state | tree: t}}
  end

  def handle_call({:bulk_update,updates},_from,state)do
    r = {_atom,t} = case state.tree do
      nil -> {:badtree,state.tree}
      _ ->
        final_rbundle = updates |> Enum.reduce(get_rbundle(state), fn {id,update} = _u,acc ->
          %{acc | tree: acc |> update_leaf(id,update)}
        end)
        {:ok,final_rbundle.tree}
    end
    {:reply, r , %__MODULE__{state | tree: t}}
  end

  @impl true
  def handle_call(:execute,_from,state)do
    r = {_atom,_t} = case state.tree do
      nil -> {:badtree,state.tree}
      _ -> {:ok,get_rbundle(state) |> execute}
    end
    {:reply, r , %__MODULE__{metadata: nil, tree: nil}}
  end

  @impl true
  def handle_call(:metadata,_from,state)do
    {:reply, state.metadata , state}
  end

  @impl true
  def handle_call(:tree,_from,state)do
    {:reply, state.tree , state}
  end

end
