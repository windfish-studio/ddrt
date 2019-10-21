alias DDRT.DynamicRtreeImpl.Utils
alias DDRT.DynamicRtree
alias DDRT.DynamicRtreeImpl.BoundingBoxGenerator

import IO.ANSI

DynamicRtree.start_link([conf: %{}])
Logger.configure([level: :info])

generate = fn n,s ->
  BoundingBoxGenerator.generate(n,s,[]) |> Enum.map(fn x -> {UUID.uuid1(),x} end)
end

new_tree = fn leafs,typ ->
  DynamicRtree.new(%{type: typ})
  DynamicRtree.insert(leafs)
end

unit_move = fn ->
  %{x: Enum.random([-1,1]), y: Enum.random([-1,1])}
end

Benchee.run(%{
  "map" =>
    {fn ml ->
        DynamicRtree.bulk_update(ml)
    end,
    before_each: fn _i -> [{_atom,ml}] = :ets.lookup(:move_list,:move)
                          ml
    end,
    after_each: fn _t ->   [{_atom,ml}] = :ets.lookup(:move_list,:move)
                          new_ml = ml |> Enum.map(fn {id,{_ob,nb}} -> {id,{nb,Utils.box_move(nb,unit_move.())}} end)
                          :ets.insert(:move_list,{:move,new_ml})
    end,
    before_scenario: fn boxes ->
      new_tree.(boxes,Map)
      move_list = boxes |> Enum.map(fn {id,box} -> {id,{box,Utils.box_move(box,unit_move.())}} end)
      :ets.new(:move_list,[:set,:named_table])
      :ets.insert(:move_list,{:move,move_list})
    end},
  "merklemap" =>
    {fn ml ->
        DynamicRtree.bulk_update(ml)
    end,
    before_each: fn _i -> [{_atom,ml}] = :ets.lookup(:move_list,:move)
                          ml
    end,
    after_each: fn _t ->   [{_atom,ml}] = :ets.lookup(:move_list,:move)
                          new_ml = ml |> Enum.map(fn {id,{_ob,nb}} -> {id,{nb,Utils.box_move(nb,unit_move.())}} end)
                          :ets.insert(:move_list,{:move,new_ml})
    end,
    before_scenario: fn boxes ->
      new_tree.(boxes,MerkleMap)
      move_list = boxes |> Enum.map(fn {id,box} -> {id,{box,Utils.box_move(box,unit_move.())}} end)

      :ets.new(:move_list,[:set,:named_table])
      :ets.insert(:move_list,{:move,move_list})
    end},

}, inputs: %{
    cyan() <>"all leafs of tree ["<> color(195) <>"1000" <> cyan() <> "]" <> reset() => generate.(1000,1),
    cyan() <>"all leafs of tree ["<> color(195) <>"100000" <> cyan() <> "]" <> reset() => generate.(100000,1)
   }, time: 10)
