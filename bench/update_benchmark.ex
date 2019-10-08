alias ElixirRtree.Utils
import IO.ANSI
size = 1

generate = fn n,s ->
  BoundingBoxGenerator.generate(n,s,[]) |> Enum.map(fn x -> {x,UUID.uuid1()} end)
end

new_tree = fn leafs ->
  boxes = generate.(leafs,size)
  tree = boxes |> Enum.reduce(Drtree.new,fn {b,i},acc ->
    acc |> Drtree.insert({i,b})
  end)
  {boxes,tree}
end

unit_move = fn ->
  %{x: Enum.random([-1,1]), y: Enum.random([-1,1])}
end


Benchee.run(%{
  #TODO : update discreto (?)
  "continuous update" =>
    {fn {t,ml} ->
        ml |> Enum.reduce(t,fn {id,ob,nb},acc ->
          acc |> Drtree.update_leaf(id,{ob,nb})
        end)
    end,
    before_each: fn _i -> [{_atom,t}] = :ets.lookup(:bench_tree,:tree)
                          [{_atom,ml}] = :ets.lookup(:move_list,:move)
                          {t,ml}
    end,
    after_each: fn t -> :ets.insert(:bench_tree,{:tree,t})
                          [{_atom,ml}] = :ets.lookup(:move_list,:move)
                          new_ml = ml |> Enum.map(fn {id,_ob,nb} -> {id,nb,Utils.box_move(nb,unit_move.())} end)
                          :ets.insert(:move_list,{:move,new_ml})
    end,
    before_scenario: fn n ->
      {b,t} = new_tree.(n)
      move_list = b |> Enum.map(fn {box,id} -> {id,box,Utils.box_move(box,unit_move.())} end)
      :ets.new(:bench_tree,[:set,:named_table])
      :ets.new(:move_list,[:set,:named_table])
      :ets.insert(:bench_tree,{:tree,t})
      :ets.insert(:move_list,{:move,move_list})
    end}
}, inputs: %{
    cyan() <>"tree ["<> color(195) <>"1000" <> cyan() <> "]" <> reset() => 1000,
    cyan() <>"tree ["<> color(195) <>"10000" <> cyan() <> "]" <> reset() => 10000,
    cyan() <>"tree ["<> color(195) <>"100000" <> cyan() <> "]" <> reset() => 100000
   }, time: 10)