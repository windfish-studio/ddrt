defmodule Drtree do
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
  @spec query(map(),bounding_box)::list(integer())
  defdelegate query(tree,box), to: ElixirRtree
  @doc """
  Find all nodes that match with the `box` query at the given `depth` of the r-tree.

  Returns `list()`

  ## Parameters

    - `tree`: Map that represents the r-tree structure.
    - `box`: Bounding box `[{x_min,x_max},{y_min,y_max}]`.
    - `depth`: Integer that define the query r-tree depth limit. Note: 0 is root node.
  """
  @spec query(map(),bounding_box,integer())::list(integer())
  defdelegate query(tree,box,depth), to: ElixirRtree
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
    ElixirRtree.new(@defopts)
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
  def new(opts)do
    good_keys = opts |> Map.keys |> Enum.filter(fn k -> constraints() |> Map.has_key?(k) and constraints()[k].(opts[k]) end)
    good_keys |> Enum.reduce(@defopts, fn k,acc ->
      acc |> Map.put(k,opts[k])
    end) |> ElixirRtree.new
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
end
