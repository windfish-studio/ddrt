defmodule ElixirRtree.Node do
  @moduledoc false

  @spec new()::charlist()

  def new()do
    UUID.uuid1()
  end

end
