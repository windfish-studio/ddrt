import IO.ANSI

Drtree.start_link(%{})

generate = fn n,s ->
  BoundingBoxGenerator.generate(n,s,[]) |> Enum.map(fn x -> {:os.system_time(:nanosecond),x} end)
end

new_tree = fn leafs,typ ->
  Drtree.new(%{type: typ})
  generate.(leafs,1)
  |> Enum.each(fn l ->
    Drtree.insert(l)
  end)
end

insert = fn data ->
  data
  |> Enum.each(fn l ->
    Drtree.insert(l)
  end)
end

bulk_insert = fn data ->
  Drtree.insert(data)
end

Benchee.run(%{
  "merklemap 1 by 1" =>
    {fn data ->
        insert.(data)
    end,
    before_each: fn boxes ->
                    new_tree.(0,MerkleMap)
                    boxes
                  end},
  "map 1 by 1" =>
    { fn data ->
         insert.(data)
    end,
    before_each: fn boxes ->
                    new_tree.(0,Map)
                    boxes
                  end},
  "merklemap bulk" =>
    {fn data ->
        bulk_insert.(data)
    end,
    before_each: fn boxes ->
                    new_tree.(0,MerkleMap)
                    boxes
    end},
  "map bulk" =>
    { fn data ->
         bulk_insert.(data)
    end,
    before_each: fn boxes ->
                    new_tree.(0,Map)
                    boxes
    end}

},  inputs: %{
          yellow() <> "1000 " <> green() <>"leafs" <> reset() => generate.(1000,1),
          #yellow() <> "1000000 " <> green() <>"leafs" <> reset() => generate.(1000000,1)
}, time: 5)


