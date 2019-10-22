defmodule DynamicRtreeTest.Distribution do
  use ExUnit.Case
  alias DDRT.DynamicRtree

  setup_all do
    {:ok, ddrt_a} = DDRT.start_link(name: A)
    {:ok, ddrt_b} = DDRT.start_link(name: B)

    DDRT.set_members(B, [A])
    DDRT.set_members(A, [B])

    on_exit(fn ->
      Process.unlink(ddrt_a)
      Process.unlink(ddrt_b)

      Process.exit(ddrt_a, :shutdown)
      Process.exit(ddrt_b, :shutdown)
    end)

    :ok
  end

  describe "[DynamicRtree distributed]" do
    test "tree insert/update/delete sync" do
      empty_tree = DDRT.tree(B)
      DDRT.insert({0, [{4, 5}, {6, 7}]}, A)
      Process.sleep(200)
      refute DDRT.tree(B) == empty_tree
      assert DeltaCrdt.read(A.Crdt) == DeltaCrdt.read(B.Crdt)
      assert DDRT.tree(A) == DDRT.tree(B)

      assert DeltaCrdt.read(A.Crdt) |> DynamicRtree.reconstruct_from_crdt(empty_tree) ==
               DDRT.tree(A)

      DDRT.insert(
        [
          {1, [{-34, -33}, {40, 41}]},
          {2, [{-50, -49}, {15, 16}]},
          {3, [{33, 34}, {-10, -9}]},
          {4, [{35, 36}, {-9, -8}]},
          {5, [{0, 1}, {-9, -8}]},
          {6, [{9, 10}, {9, 10}]}
        ],
        B
      )

      refute DDRT.tree(A) == DDRT.tree(B)
      Process.sleep(200)
      assert DDRT.tree(A) == DDRT.tree(B)

      DDRT.update(0, [{10, 11}, {16, 17}], A)
      old_tree = DDRT.tree(B)
      Process.sleep(200)
      refute DDRT.tree(B) == old_tree
      assert DeltaCrdt.read(A.Crdt) == DeltaCrdt.read(B.Crdt)
      assert DDRT.tree(A) == DDRT.tree(B)

      DDRT.bulk_update(
        [
          {1, [{-4, -3}, {4, 5}]},
          {2, [{-5, -4}, {5, 6}]},
          {3, [{3, 4}, {0, 1}]},
          {4, [{5, 6}, {-9, -8}]},
          {5, [{10, 11}, {-9, -8}]},
          {6, [{9, 10}, {19, 20}]}
        ],
        B
      )

      refute DDRT.tree(A) == DDRT.tree(B)
      Process.sleep(200)
      assert DDRT.tree(A) == DDRT.tree(B)

      DDRT.delete(0, A)
      old_tree = DDRT.tree(B)
      Process.sleep(200)
      refute DDRT.tree(B) == old_tree
      assert DeltaCrdt.read(A.Crdt) == DeltaCrdt.read(B.Crdt)
      assert DDRT.tree(A) == DDRT.tree(B)

      DDRT.delete([1, 2, 3, 4, 5, 6], B)
      refute DDRT.tree(A) == DDRT.tree(B)
      Process.sleep(200)
      assert DDRT.tree(A) == DDRT.tree(B)

      send(A, {:nodeup, [], []})
      send(A, {:nodedown, [], []})
      send(B, {:nodeup, [], []})
      send(B, {:nodedown, [], []})
    end
  end
end
