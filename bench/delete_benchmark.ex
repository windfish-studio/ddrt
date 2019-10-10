import IO.ANSI
generate = fn n,s ->
  BoundingBoxGenerator.generate(n,s,[]) |> Enum.map(fn x -> {x,UUID.uuid1()} end)
end

new_tree = fn boxes,s,typ ->
  boxes |> Enum.slice(0..s-1) |> Enum.reduce(Drtree.new(%{type: typ}),fn {b,i},acc ->
    acc |> Drtree.insert({i,b})
  end)
end

boxes = generate.(100000,1)

delete = fn t,id ->
  Drtree.delete(t,id)
end

random_leaf = fn leafs,limit ->
  leafs |> Enum.at(Enum.random(0..limit-1))
end

reinsert_cache = fn t,{box,id} ->
  t[:metadata][:ets_table] |> :ets.insert({id,box,:leaf})
end

Benchee.run(%{
  "map" =>
    {fn {t,{_box,id} = leaf} ->
        delete.(t,id)
        {t,leaf}
  end,
    before_each: fn n -> {new_tree.(boxes,n,Map),random_leaf.(boxes,n)} end,
    after_each: fn {t,l} -> reinsert_cache.(t,l) end},
  "merklemap" =>
    {fn {t,{_box,id} = leaf} ->
        delete.(t,id)
        {t,leaf}
  end,
    before_each: fn n -> {new_tree.(boxes,n,MerkleMap),random_leaf.(boxes,n)} end,
    after_each: fn {t,l} -> reinsert_cache.(t,l) end}

}, inputs: %{
    cyan() <>"random leaf of tree ["<> color(195) <>"1000" <> cyan() <> "]" <> reset() => 1000,
    cyan() <>"random leaf of tree ["<> color(195) <>"100000" <> cyan() <> "]" <> reset() => 100000
  }
)