defmodule ElixirRtree.Node do
  @moduledoc false

  @spec new(%{},[integer()])::tuple()

  def new(gen,seed)do
    gen[:next].(seed)
  end


end
