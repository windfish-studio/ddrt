defmodule DrtreeTest.Distribution do
  use ExUnit.Case

  setup_all do
    children = [
      {Cluster.Supervisor, [Application.get_env(:libcluster,:topologies), [name: A.ClusterSupervisor]]},
      {DeltaCrdt, [crdt: DeltaCrdt.AWLWWMap, name: CrdtA, on_diffs: &DDRT.on_diffs(&1,Drtree,A)]},
      {Drtree, [conf: %{mode: :distributed}, name: A, crdt: CrdtA]}
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: A.Supervisor)

    children = [
      {Cluster.Supervisor, [Application.get_env(:libcluster,:topologies), [name: B.ClusterSupervisor]]},
      {DeltaCrdt, [crdt: DeltaCrdt.AWLWWMap, name: CrdtB, on_diffs: &DDRT.on_diffs(&1,Drtree,B)]},
      {Drtree, [conf: %{mode: :distributed}, name: B, crdt: CrdtB]}
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: B.Supervisor)

    DeltaCrdt.set_neighbours(CrdtB, [CrdtA])
    DeltaCrdt.set_neighbours(CrdtA, [CrdtB])
    {:ok, %{}}
  end

  describe "[Drtree distributed]" do

    test "tree insert/update/delete sync" do
      Drtree.insert({0,[{4,5},{6,7}]},A)
      empty_tree = Drtree.tree(B)
      Process.sleep(1000)
      refute Drtree.tree(B) == empty_tree
      assert DeltaCrdt.read(CrdtA) == DeltaCrdt.read(CrdtB)
      assert Drtree.tree(A) == Drtree.tree(B)
      assert DeltaCrdt.read(CrdtA) |> Drtree.reconstruct_from_crdt(empty_tree) == Drtree.tree(A)

      Drtree.insert([{1,[{-34,-33},{40,41}]},{2,[{-50,-49},{15,16}]},{3,[{33,34},{-10,-9}]},{4,[{35,36},{-9,-8}]},{5,[{0,1},{-9,-8}]},{6,[{9,10},{9,10}]}],B)
      refute Drtree.tree(A) == Drtree.tree(B)
      Process.sleep(1000)
      assert Drtree.tree(A) == Drtree.tree(B)

      Drtree.update(0,[{10,11},{16,17}],A)
      old_tree = Drtree.tree(B)
      Process.sleep(1000)
      refute Drtree.tree(B) == old_tree
      assert DeltaCrdt.read(CrdtA) == DeltaCrdt.read(CrdtB)
      assert Drtree.tree(A) == Drtree.tree(B)

      Drtree.updates([{1,[{-4,-3},{4,5}]},{2,[{-5,-4},{5,6}]},{3,[{3,4},{0,1}]},{4,[{5,6},{-9,-8}]},{5,[{10,11},{-9,-8}]},{6,[{9,10},{19,20}]}],B)
      refute Drtree.tree(A) == Drtree.tree(B)
      Process.sleep(1000)
      assert Drtree.tree(A) == Drtree.tree(B)

      Drtree.delete(0,A)
      old_tree = Drtree.tree(B)
      Process.sleep(1000)
      refute Drtree.tree(B) == old_tree
      assert DeltaCrdt.read(CrdtA) == DeltaCrdt.read(CrdtB)
      assert Drtree.tree(A) == Drtree.tree(B)

      Drtree.delete([1,2,3,4,5,6],B)
      refute Drtree.tree(A) == Drtree.tree(B)
      Process.sleep(1000)
      assert Drtree.tree(A) == Drtree.tree(B)

      send(A,{:nodeup,[],[]})
      send(A,{:nodedown,[],[]})
      send(B,{:nodeup,[],[]})
      send(B,{:nodedown,[],[]})
    end
  end
end