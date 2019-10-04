defmodule Drtree do
  @moduledoc false

  @defopts %{
    width: 6,
    type: :standalone,
    verbose: false,
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
