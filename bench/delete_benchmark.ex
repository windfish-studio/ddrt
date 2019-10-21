import IO.ANSI

alias DDRT.DynamicRtreeImpl.Utils
alias DDRT.DynamicRtree
alias DDRT.DynamicRtreeImpl.BoundingBoxGenerator

DynamicRtree.start_link([conf: %{}])
Logger.configure([level: :info])

generate = fn n,s ->
  BoundingBoxGenerator.generate(n,s,[]) |> Enum.map(fn x -> {UUID.uuid1(),x} end)
end

new_tree = fn boxes,typ ->
  DynamicRtree.new(%{type: typ})
  DynamicRtree.insert(boxes)
end

Benchee.run(%{
  "map bulk" =>
    {fn ids ->
        DynamicRtree.delete(ids)
  end,
    before_each: fn n ->
                    new_tree.(n,Map)
                    n |> Enum.map(fn {id,_box}-> id end)
                  end},
  "merklemap bulk" =>
    {fn ids ->
        DynamicRtree.delete(ids)
  end,
    before_each: fn n ->
                    new_tree.(n,MerkleMap)
                    n |> Enum.map(fn {id,_box}-> id end)
                  end},
  "map 1 by 1" =>
    {fn ids ->
      ids |> Enum.each(fn id -> DynamicRtree.delete(id) end)
  end,
    before_each: fn n ->
                    new_tree.(n,Map)
                    n |> Enum.map(fn {id,_box}-> id end)
    end},
  "merklemap 1 by 1" =>
    {fn ids ->
        ids |> Enum.each(fn id -> DynamicRtree.delete(id) end)
  end,
    before_each: fn n ->
                    new_tree.(n,MerkleMap)
                    n |> Enum.map(fn {id,_box}-> id end)
    end},

}, inputs: %{
    cyan() <>"delete all leafs of tree ["<> color(195) <>"1000" <> cyan() <> "]" <> reset() => generate.(1000,1),
    #cyan() <>"all leafs of tree ["<> color(195) <>"100000" <> cyan() <> "]" <> reset() => generate.(100000,1)
  }
)
