defmodule Drtree do
  @moduledoc false
  defdelegate insert(tree,leaf), to: ElixirRtree
  defdelegate query(tree,box), to: ElixirRtree
  defdelegate delete(tree,id), to: ElixirRtree
  defdelegate update_leaf(tree,id,update), to: ElixirRtree

  @defopts %{
    width: 6,
    type: :standalone,
    verbose: false, #TODO: This crazy american prefers Logger comparison than the verbose flag ùwú
    database: false,
  }

  def new()do
    ElixirRtree.new(@defopts)
  end

  def new(opts)do
    opts |> Map.keys |> Enum.reduce(@defopts, fn k,acc ->
      acc |> Map.put(k,opts[k])
    end) |> ElixirRtree.new
  end
end
