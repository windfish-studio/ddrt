defmodule DrtreeTest do
  use ExUnit.Case
  alias ElixirRtree.Utils

  setup_all do
    Drtree.start_link(%{})
    {:ok, %{}}
  end

  describe "[Drtree creation]" do
    test "always returns {:ok,map()}" do
      {:ok,t} = Drtree.new
      assert Drtree.new |> is_tuple()
      assert t |> is_map()
    end

    test "raise badMapError with not map opts input" do
      assert_raise FunctionClauseError, fn -> Drtree.new([1,2,3]) end
      assert_raise FunctionClauseError, fn -> Drtree.new(1) end
      assert_raise FunctionClauseError, fn -> Drtree.new(:map) end
      assert_raise FunctionClauseError, fn -> Drtree.new("pokemon") end
    end
  end

  describe "[Drtree actions]" do

    test "insert and bulk insert works as expected" do
      Drtree.new
      metadata = Drtree.metadata
      new_tuple = {new_node,new_box} = {UUID.uuid1,BoundingBoxGenerator.generate(1,1,[]) |> List.first}
      ets = metadata[:ets_table]
      {:ok,t} = Drtree.insert(new_tuple)
      {cont,parent} = t[new_node]
      assert cont == :leaf
      assert parent == t['root']
      assert ets |> :ets.lookup(new_node) == [{new_node,new_box,:leaf}]

      assert Drtree.execute
      assert Drtree.tree == nil
      assert Drtree.metadata == nil
      assert Drtree.insert(new_tuple) == {:badtree,nil}

      Drtree.new
      {:ok,t} = Drtree.insert([{0,[{4,5},{6,7}]},{1,[{-34,-33},{40,41}]},{2,[{-50,-49},{15,16}]},{3,[{33,34},{-10,-9}]},{4,[{35,36},{-9,-8}]},{5,[{0,1},{-9,-8}]},{6,[{9,10},{9,10}]}])
      metadata = Drtree.metadata

      root =  t['root']
      {ch,root_ptr} = t[root]
      assert (t |> Enum.to_list |> length) == t |> Enum.uniq |> length
      assert length(ch) == 2
      [{_id,box,_l}] = metadata[:ets_table] |> :ets.lookup(root)
      assert box == [{-50,36},{-10,41}]
      assert Drtree.execute == {:ok,true}
    end

    test "delete leaf keeps tree consistency" do
      Drtree.new
      metadata = Drtree.metadata
      data = BoundingBoxGenerator.generate(100,1,[]) |> Enum.with_index |> Enum.map(fn {x,i} -> {i,x} end)
      {:ok,t} = Drtree.insert(data)
      delete_id = 90
      old_parent = t[delete_id] |> elem(1)
      old_parent_childs = t[old_parent] |> elem(0)
      ets = metadata[:ets_table]

      assert ets |> :ets.member(delete_id)
      refute t[delete_id] == nil
      assert delete_id in old_parent_childs

      {:ok,t} = Drtree.delete(delete_id)

      refute ets |> :ets.member(delete_id)
      assert t[delete_id] == nil
      refute delete_id in (t[old_parent] |> elem(0))

      {:ok,same_t} = Drtree.delete(delete_id)

      assert t = same_t

      {:ok,t} = Drtree.delete((1..100) |> Enum.map(fn x -> x end))
      root = t['root']
      {ch,parent} = t[root]
      [{_id,leaf_box,_l}] = ets |> :ets.lookup(0)
      [{_id,root_box,_l}] = ets |> :ets.lookup(root)
      assert length(ch) == 1
      assert leaf_box == root_box
      {:ok,t} = Drtree.delete(0)
      assert length(t[root] |> elem(0)) == 0
      [{_id,root_box,_l}] = ets |> :ets.lookup(root)
      assert root_box == [{0,0},{0,0}]
    end

    test "queries return good stuff" do
        Drtree.new
        {:ok,t} = Drtree.insert([{0,[{4,5},{6,7}]},{1,[{-34,-33},{40,41}]},{2,[{-50,-49},{15,16}]},{3,[{33,34},{-10,-9}]},{4,[{35,36},{-9,-8}]},{5,[{0,1},{-9,-8}]},{6,[{9,10},{9,10}]}])

        assert Drtree.query([{4,5},{6,7}]) == {:ok,[0]}
        assert Drtree.query([{2,5},{1,6.1}]) == {:ok,[0]}
        assert Drtree.query([{-60,0},{0,100}]) |> elem(1) |> Enum.sort == [1,2]
        assert Drtree.query([{-100,100},{-100,100}]) |> elem(1) |> Enum.sort == [0,1,2,3,4,5,6]
        assert Drtree.query([{1,2},{1,2}]) == {:ok,[]}
        assert Drtree.query([{0,0},{0,0}]) == {:ok,[]}
        assert Drtree.query([{4,5},{6,7}],0) == {:ok,[33762080631324007]}
        assert Drtree.query([{4,5},{6,7}],1) == {:ok,[101671470050757358]}
        assert Drtree.query([{4,5},{6,7}],2) == {:ok,[0]}
        assert Drtree.query([{4,5},{6,7}],1000) == {:ok,[0]}
        assert Drtree.query([{44,45},{-7,6}],0) == {:ok,[]}
        assert Drtree.query([{44,45},{-7,6}],1) == {:ok,[]}
        assert Drtree.query([{44,45},{-7,6}],2) == {:ok,[]}

        Drtree.new
        assert Drtree.query([{4,5},{6,7}]) == {:ok,[]}
        assert Drtree.query([{-60,0},{0,100}]) == {:ok,[]}
        assert Drtree.query([{-100,100},{-100,100}]) == {:ok,[]}
        assert Drtree.query([{1,2},{1,2}]) == {:ok,[]}
        assert Drtree.query([{0,0},{0,0}]) == {:ok,[]}
    end

    test "hard update works"do

      Drtree.new
      metadata = Drtree.metadata
      {:ok,t} = Drtree.insert([{0,[{4,5},{6,7}]},{1,[{-34,-33},{40,41}]},{2,[{-50,-49},{15,16}]},{3,[{33,34},{-10,-9}]},{4,[{35,36},{-9,-8}]},{5,[{0,1},{-9,-8}]},{6,[{9,10},{9,10}]}])

      ets = metadata[:ets_table]
      [{_id,root_box,_l}] = ets |> :ets.lookup(t['root'])
      [{_id,leaf_box,_l}] = ets |> :ets.lookup(2)
      assert root_box == [{-50,36},{-10,41}]
      assert leaf_box == [{-50,-49},{15,16}]

      # best case
      {:leaf,p} = t[0]
      {:ok,t} = Drtree.update(0,[{13,14},{6,7}])
      assert p == (t[0] |> elem(1))

      # good case
      {:leaf,p} = t[0]
      {:ok,t} = Drtree.update(5,[{-1,0},{-8,-7}])
      assert p == (t[0] |> elem(1))

      # neutral case
      {:leaf,p} = t[0]
      {:ok,t} = Drtree.update(0,[{-5,-4},{6,7}])
      refute p == (t[0] |> elem(1))
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
