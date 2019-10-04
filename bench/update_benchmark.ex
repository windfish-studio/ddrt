alias ElixirRtree.Utils
size = 1

generate = fn n,s ->
  BoundingBoxGenerator.generate(n,s,[]) |> Enum.map(fn x -> {x,ElixirRtree.Node.new()} end)
end

new_tree = fn leafs ->
  boxes = generate.(leafs,size)
  tree = boxes |> Enum.reduce(Drtree.new,fn {b,i},acc ->
    acc |> ElixirRtree.insert({i,b})
  end)
  {boxes,tree}
end

unit_move = fn ->
  %{x: Enum.random([-1,1]), y: Enum.random([-1,1])}
end


Benchee.run(%{
  "continuous update" =>
    {fn {t,ml} ->
        ml |> Enum.reduce(t,fn {id,ob,nb},acc ->
          acc |> ElixirRtree.update_leaf(id,{ob,nb})
        end)
    end,
    before_each: fn _i -> [{_atom,t}] = :ets.lookup(:bench_tree,:tree)
                          [{atom,ml}] = :ets.lookup(:move_list,:move)
                          {t,ml}
    end,
    after_each: fn t -> :ets.insert(:bench_tree,{:tree,t})
                          [{atom,ml}] = :ets.lookup(:move_list,:move)
                          new_ml = ml |> Enum.map(fn {id,ob,nb} -> {id,nb,Utils.box_move(nb,unit_move.())} end)
                          :ets.insert(:move_list,{:move,ml})
    end,
    before_scenario: fn _i ->
      {b,t} = new_tree.(10000)
      move_list = b |> Enum.map(fn {box,id} -> {id,box,Utils.box_move(box,unit_move.())} end)
      :ets.new(:bench_tree,[:set,:named_table])
      :ets.new(:move_list,[:set,:named_table])
      :ets.insert(:bench_tree,{:tree,t})
      :ets.insert(:move_list,{:move,move_list})
    end}
})