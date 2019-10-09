defmodule ElixirRtree.Node do
  @moduledoc false

  def new(gen,seed)do
    gen[:next].(seed)
  end


end
