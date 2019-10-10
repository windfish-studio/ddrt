import IO.ANSI
generate = fn n,s ->
  BoundingBoxGenerator.generate(n,s,[]) |> Enum.map(fn x -> {x,UUID.uuid1()} end)
end

new_tree = fn leafs,typ ->
  generate.(leafs,1)
  |> Enum.reduce(Drtree.new(%{type: typ}),fn {b,i},acc ->
    acc |> Drtree.insert({i,b})
  end)
end

insert = fn t,data ->
  data
  |> Enum.reduce(t,fn {b,i},acc ->
    acc |> Drtree.insert({i,b})
  end)
end

flush_cache = fn t ->
  t[:metadata][:ets_table] |> :ets.delete
end

Benchee.run(%{
  "merklemap" =>
    {fn {t,data} ->
        insert.(t,data)
  end,
    before_each: fn boxes -> {new_tree.(0,MerkleMap),boxes} end,
    after_each: fn rt -> flush_cache.(rt) end},
  "map" =>
    { fn {t,data} ->
          insert.(t,data)
    end,
    before_each: fn boxes -> {new_tree.(0,Map),boxes} end,
    after_each: fn  rt -> flush_cache.(rt) end}

},  inputs: %{
          yellow() <> "1000 " <> green() <>"leafs" <> reset() => generate.(1000,1),
          yellow() <> "100000 " <> green() <>"leafs" <> reset() => generate.(100000,1)
}, time: 5)
