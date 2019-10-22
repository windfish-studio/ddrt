defmodule DDRT do
  use DDRT.DynamicRtree
  alias DDRT.DynamicRtree

  @moduledoc """
  This is the top-level `DDRT` module. Use this to create a distributed r-tree. If you're only interested in using this package for the r-tree implementation, you should instead use `DDRT.DynamicRtree`
  """
  
  #DDRT party begins.
  @doc """

  These are all of the possible DDRT configuration parameters and their default values.

  ```
  [
    name: DDRT,
    width: 6,
    verbose: false,
    seed: 0
  ]
  ```
  """
  @spec start_link(DynamicRtree.tree_config()) :: {:ok, pid}
  def start_link(opts) do
    name = Keyword.get(opts, :name, DynamicRtree)

    children = [
      {DeltaCrdt,
       [
         crdt: DeltaCrdt.AWLWWMap,
         name: Module.concat([name, Crdt]),
         on_diffs: &on_diffs(&1, DynamicRtree, name)
       ]},
      {DynamicRtree,
       [
         conf: Keyword.put_new(opts, :mode, :distributed),
         crdt: Module.concat([name, Crdt]),
         name: name
       ]}
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Module.concat([name, Supervisor])
    )
  end

  @doc false
  def on_diffs(diffs, mod, name) do
    mod.merge_diffs(diffs, name)
  end
end
