import IO.ANSI
generate = fn n,s ->
  BoundingBoxGenerator.generate(n,s,[]) |> Enum.map(fn x -> {x,UUID.uuid1()} end)
end

new_tree = fn leafs ->
  generate.(leafs,1)
  |> Enum.reduce(Drtree.new,fn {b,i},acc ->
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
  "tree [100000]" =>
    {fn {t,data} ->
        insert.(t,data)
  end,
    before_each: fn boxes -> {new_tree.(100000),boxes} end,
    after_each: fn rt -> flush_cache.(rt) end},
  "tree [empty]" =>
    { fn {t,data} ->
          insert.(t,data)
    end,
    before_each: fn boxes -> {new_tree.(0),boxes} end,
    after_each: fn  rt -> flush_cache.(rt) end}

},  inputs: %{
          yellow() <> "1000 " <> green() <>"leafs" <> reset() => generate.(1000,1),
          yellow() <> "10000 " <> green() <>"leafs" <> reset() => generate.(10000,1),
          yellow() <> "100000 " <> green() <>"leafs" <> reset() => generate.(100000,1)
}, time: 5)
