defmodule Drtree do
  @moduledoc false
  defdelegate insert(tree,leaf), to: ElixirRtree
  defdelegate query(tree,box), to: ElixirRtree
  defdelegate delete(tree,id), to: ElixirRtree
  defdelegate update_leaf(tree,id,update), to: ElixirRtree
  defdelegate execute(tree), to: ElixirRtree


  @opt_values %{
    type: [:standalone,:merkle,:distributed],
    access: [:protected, :public, :private]
  }

  @defopts %{
    width: 6,
    type: :standalone,
    verbose: false, #TODO: This crazy american prefers Logger comparison than the verbose flag ùwú
    database: false,
    access: :protected,
    seed: 0
  }

  def new()do
    ElixirRtree.new(@defopts)
  end

  def new(opts)do
    good_keys = opts |> Map.keys |> Enum.filter(fn k -> constraints() |> Map.has_key?(k) and constraints()[k].(opts[k]) end)
    good_keys |> Enum.reduce(@defopts, fn k,acc ->
      acc |> Map.put(k,opts[k])
    end) |> ElixirRtree.new
  end


  def default_params()do
    @defopts
  end

  def constraints()do
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
