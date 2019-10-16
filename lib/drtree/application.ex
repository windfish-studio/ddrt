defmodule Drtree.Application do
  use Application
  @moduledoc false

  def start(_type, _args) do

    children = [
      {Cluster.Supervisor, [Application.get_env(:libcluster,:topologies), [name: Drtree.ClusterSupervisor]]},
      {DeltaCrdt, [crdt: DeltaCrdt.AWLWWMap, name: DrtreeCrdt, on_diffs: &on_diffs(&1,Drtree)]},
      {Drtree, [conf: %{mode: :distributed}, crdt: DrtreeCrdt]}
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: Drtree.Supervisor)
  end

  def on_diffs(diffs,mod,name \\ Drtree) do
    mod.merge_diffs(diffs,name)
  end
end
