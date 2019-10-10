defmodule DrtreeTest do
  use ExUnit.Case
  alias ElixirRtree.Utils

  def insert(t,leafs)do
    BoundingBoxGenerator.generate(leafs,1,[])
    |> Enum.with_index
    |> Enum.reduce(t,fn {b,i},acc ->
      acc |> Drtree.insert({i,b})
    end)
  end

  def create_tree(perm)do
    Drtree.new(%{access: perm})
  end

  setup_all do
    public_tree = create_tree(:public) |> insert(100)
    protected_tree = create_tree(:protected) |> insert(100)
    private_tree = create_tree(:private) |> insert(100)
    {:ok, %{public_tree: public_tree , protected_tree: protected_tree, private_tree: private_tree}}
  end

  describe "[Drtree creation]" do
    test "always returns a map" do
      assert Drtree.new |> is_map
    end

    test "default params keep consistency" do
      assert Drtree.new[:metadata][:params] == Drtree.default_params
      assert Drtree.new(%{})[:metadata][:params] == Drtree.default_params
    end

    test "opts params keep consistency" do
      assert Drtree.new(%{database: :dumb})[:metadata][:database] == nil
      assert Drtree.new(%{database: false})[:metadata][:database] == nil
      assert Drtree.new(%{verbose: true})[:metadata][:params] == %{Drtree.default_params | verbose: true}
      assert Drtree.new(%{width: 10})[:metadata][:params] == %{Drtree.default_params | width: 10}
      assert Drtree.new(%{type: :standalone})[:metadata][:params] == %{Drtree.default_params | type: Map}
      assert Drtree.new(%{seed: 11})[:metadata][:params] == %{Drtree.default_params | seed: 11}
      refute Drtree.new(%{access: :nothing})[:metadata][:params] == %{Drtree.default_params | access: :public}
      refute Drtree.new(%{verbose: :wat})[:metadata][:params] == %{Drtree.default_params | verbose: :wat}
      refute Drtree.new(%{something: true})[:metadata][:params] == Drtree.default_params |> Map.put(:something,true)
    end

    test "raise badMapError with not map opts input" do
      assert_raise BadMapError, fn -> Drtree.new([1,2,3]) end
      assert_raise BadMapError, fn -> Drtree.new(1) end
      assert_raise BadMapError, fn -> Drtree.new(:map) end
      assert_raise BadMapError, fn -> Drtree.new("pokemon") end
    end
  end

  describe "[Drtree actions]" do

    test "insert new leaf on empty tree keeps consistency",state do
      empty_tree = Drtree.new
      new_tuple = {new_node,new_box} = {UUID.uuid1,BoundingBoxGenerator.generate(1,1,[]) |> List.first}
      ets = empty_tree[:metadata][:ets_table]
      inserted_tree = Drtree.insert(empty_tree,new_tuple)
      assert inserted_tree[new_node] == :leaf
      assert inserted_tree[:parents][new_node] == inserted_tree['root']
      assert ets |> :ets.lookup(new_node) == [{new_node,new_box,:leaf}]

      assert empty_tree |> Drtree.execute

      full_tree =  Drtree.new
                   |> Drtree.insert({0,[{4,5},{6,7}]})
                   |> Drtree.insert({1,[{-34,-33},{40,41}]})
                   |> Drtree.insert({2,[{-50,-49},{15,16}]})
                   |> Drtree.insert({3,[{33,34},{-10,-9}]})
                   |> Drtree.insert({4,[{35,36},{-9,-8}]})
                   |> Drtree.insert({5,[{0,1},{-9,-8}]})
                   |> Drtree.insert({6,[{9,10},{9,10}]})

      root = full_tree |> Map.get('root')
      assert (full_tree |> Enum.to_list |> length) == full_tree |> Enum.uniq |> length
      assert length(full_tree |> Map.get(root)) == 2
      [{_id,box,_l}] = full_tree[:metadata][:ets_table] |> :ets.lookup(root)
      assert box == [{-50,36},{-10,41}]
      assert full_tree |> Drtree.execute

      assert_raise ArgumentError, fn -> Drtree.insert(state.protected_tree,{UUID.uuid1,BoundingBoxGenerator.generate(1,1,[]) |> List.first}) end
      assert_raise ArgumentError, fn -> Drtree.insert(state.private_tree,{UUID.uuid1,BoundingBoxGenerator.generate(1,1,[]) |> List.first}) end
    end

    test "delete leaf keeps tree consistency",state do
      local_tree = Drtree.new |> insert(100)
      delete_id = 90
      old_parent = local_tree[:parents][delete_id]
      old_parent_childs = local_tree[old_parent]
      ets = local_tree[:metadata][:ets_table]

      assert ets |> :ets.member(delete_id)
      refute local_tree[delete_id] == nil
      refute local_tree[:parents][delete_id] == nil
      assert delete_id in old_parent_childs

      new_tree = Drtree.delete(local_tree,delete_id)

      refute ets |> :ets.member(delete_id)
      assert new_tree[delete_id] == nil
      assert new_tree[:parents][delete_id] == nil
      refute delete_id in new_tree[old_parent]

      same_tree =  Drtree.delete(new_tree,delete_id)

      assert new_tree = same_tree

      final_tree = (1..100) |> Enum.reduce(new_tree,fn i,acc ->
        acc |> Drtree.delete(i)
      end)

      root = final_tree |> Map.get('root')
      [{_id,leaf_box,_l}] = ets |> :ets.lookup(0)
      [{_id,root_box,_l}] = ets |> :ets.lookup(root)
      assert length(final_tree |> Map.get(root)) == 1
      assert leaf_box == root_box
      assert length(final_tree |> Drtree.delete(0) |> Map.get(root)) == 0
      [{_id,root_box,_l}] = ets |> :ets.lookup(root)
      assert root_box == [{0,0},{0,0}]
      assert local_tree |> Drtree.execute
      assert_raise ArgumentError, fn -> Drtree.delete(state.protected_tree,19) end
      assert_raise ArgumentError, fn -> Drtree.delete(state.private_tree,19) end
    end

    test "queries return good stuff",state do
        t = Drtree.new
            |> Drtree.insert({0,[{4,5},{6,7}]})
            |> Drtree.insert({1,[{-34,-33},{40,41}]})
            |> Drtree.insert({2,[{-50,-49},{15,16}]})
            |> Drtree.insert({3,[{33,34},{-10,-9}]})
            |> Drtree.insert({4,[{35,36},{-9,-8}]})
            |> Drtree.insert({5,[{0,1},{-9,-8}]})
            |> Drtree.insert({6,[{9,10},{9,10}]})

        assert Drtree.query(t,[{4,5},{6,7}]) == [0]
        assert Drtree.query(t,[{2,5},{1,6.1}]) == [0]
        assert Drtree.query(t,[{-60,0},{0,100}]) |> Enum.sort == [1,2]
        assert Drtree.query(t,[{-100,100},{-100,100}]) |> Enum.sort == [0,1,2,3,4,5,6]
        assert Drtree.query(t,[{1,2},{1,2}]) == []
        assert Drtree.query(t,[{0,0},{0,0}]) == []
        assert Drtree.query(t,[{4,5},{6,7}],0) == [33762080631324007]
        assert Drtree.query(t,[{4,5},{6,7}],1) == [101671470050757358]
        assert Drtree.query(t,[{4,5},{6,7}],2) == [0]
        assert Drtree.query(t,[{4,5},{6,7}],1000) == [0]
        assert Drtree.query(t,[{44,45},{-7,6}],0) == []
        assert Drtree.query(t,[{44,45},{-7,6}],1) == []
        assert Drtree.query(t,[{44,45},{-7,6}],2) == []

        assert t |> Drtree.execute
        nt = Drtree.new

        assert Drtree.query(nt,[{4,5},{6,7}]) == []
        assert Drtree.query(nt,[{-60,0},{0,100}]) == []
        assert Drtree.query(nt,[{-100,100},{-100,100}]) == []
        assert Drtree.query(nt,[{1,2},{1,2}]) == []
        assert Drtree.query(nt,[{0,0},{0,0}]) == []

        assert nt |> Drtree.execute

        assert Drtree.query(state.public_tree,[{-60,0},{0,100}]) |> is_list
        assert Drtree.query(state.protected_tree,[{-60,0},{0,100}]) |> is_list
        assert_raise ArgumentError, fn -> Drtree.query(state.private_tree,[{-60,0},{0,100}]) end
    end

    test "hard update works"do

      t = Drtree.new
          |> Drtree.insert({0,[{12,13},{6,7}]})
          |> Drtree.insert({1,[{-34,-33},{40,41}]})
          |> Drtree.insert({2,[{-50,-49},{15,16}]})
          |> Drtree.insert({3,[{33,34},{-10,-9}]})
          |> Drtree.insert({4,[{35,36},{-9,-8}]})
          |> Drtree.insert({5,[{0,1},{-9,-8}]})
          |> Drtree.insert({6,[{9,10},{9,10}]})
          |> Drtree.update_leaf(2,[{-49,-48},{15,16}])



      ets = t[:metadata][:ets_table]
      [{_id,root_box,_l}] = ets |> :ets.lookup(t['root'])
      [{_id,leaf_box,_l}] = ets |> :ets.lookup(2)
      assert root_box == [{-49,36},{-10,41}]
      assert leaf_box == [{-49,-48},{15,16}]

      # best case
      parent_here = t[:parents][0]
      t = t |> Drtree.update_leaf(0,[{13,14},{6,7}])
      assert parent_here == t[:parents][0]

      # good case
      parent_here = t[:parents][0]
      t = t |> Drtree.update_leaf(5,[{-1,0},{-8,-7}])
      assert parent_here == t[:parents][0]

      # neutral case
      parent_here = t[:parents][0]
      t = t |> Drtree.update_leaf(0,[{-5,-4},{6,7}])
      refute parent_here == t[:parents][0]

      # other cases cant be testes bc depends of some variable values

      BoundingBoxGenerator.generate(100,1,[]) |> Enum.reduce({t,[{-49,-48},{15,16}]}, fn b,{tree,ob} = _acc ->
        [{_id,leaf_box,_l}] = ets |> :ets.lookup(2)
        assert leaf_box == ob
        {tree |> Drtree.update_leaf(2,b),b}
      end)

      assert t |> Drtree.execute
    end

  end

  describe "[Drtree geometry operations]" do
    test "combination of bounding boxes" do
      assert Utils.combine([{3,19},{-4,20}],[{-5,6},{-4,11}]) == [{-5,19},{-4,20}]
      assert Utils.combine_multiple([[{3,19},{-4,20}],[{5,6},{-4,11}],[{0,0},{0,0}]]) == [{3,19},{-4,20}]
    end

    test "overlapping of bounding boxes" do
      refute Utils.overlap?([{0,0},{0,1}],[{1,2},{-1,5}])
      assert Utils.overlap?([{1,2},{0,1}],[{1,2},{-1,5}])
      refute Utils.overlap?([{10,12},{10,11}],[{1,2},{-1,5}])
      assert Utils.overlap?([{0,10},{0,10}],[{0,5},{0,5}])

      assert Utils.overlap_area([{0,0},{0,1}],[{1,2},{-1,5}]) == 0
      assert Utils.overlap_area([{1,2},{0,1}],[{1,2},{-1,5}]) == 100
      assert Utils.overlap_area([{10,12},{10,11}],[{1,2},{-1,5}]) == 0
      assert Utils.overlap_area([{0,10},{0,10}],[{0,5},{0,5}]) == 25

      refute Utils.contained?([{0,0},{0,1}],[{1,2},{-1,5}])
      refute Utils.contained?([{1,2},{0,1}],[{1,2},{-1,5}])
      refute Utils.contained?([{10,12},{10,11}],[{1,2},{-1,5}])
      assert Utils.contained?([{0,10},{0,10}],[{0,5},{0,5}])
      assert Utils.contained?([{0,10},{0,10}],[{0,0},{0,0}])

      assert Utils.in_border?([{0,10},{0,10}],[{0,5},{0,5}])
      refute Utils.in_border?([{10,12},{10,11}],[{1,2},{-1,5}])
      refute Utils.in_border?([{0,10},{0,10}],[{2,5},{2,5}])
    end

    test "area operations" do
      assert Utils.enlargement_area([{10,12},{10,11}],[{1,2},{-1,5}]) == 130
      assert Utils.enlargement_area([{0,10},{0,10}],[{2,5},{2,5}]) == 0
      assert Utils.enlargement_area([{0,10},{0,10}],[{0,5},{0,5}]) == 0

      assert Utils.area([{0,0},{0,0}]) == -1
      assert Utils.area([{0,1},{0,1}]) == 1
      assert Utils.area([{-1,0},{0,1}]) == 1
      assert Utils.area([{-10,0},{0,1}]) == 10

      assert Utils.middle_value([{10,12},{10,11}]) == 43/2

      assert Utils.get_posxy([{10,12},{10,11}]) == %{x: 11, y: 10.5}

      assert Utils.box_move([{10,12},{10,11}],[x: 1,y: -1]) == [{11,13},{9,10}]
    end
  end

end
