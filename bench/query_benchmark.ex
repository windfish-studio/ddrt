import IO.ANSI
generate = fn n,s ->
  BoundingBoxGenerator.generate(n,s,[]) |> Enum.map(fn x -> {x,UUID.uuid1()} end)
end

new_tree = fn boxes,typ ->
  boxes |> Enum.reduce(Drtree.new(%{type: typ}),fn {b,i},acc ->
    acc |> Drtree.insert({i,b})
  end)
end

boxes = generate.(1000,1)

Benchee.run(%{
  "map" =>
  {fn {t,b} -> Drtree.query(t,b)
  end,
  before_scenario: fn b -> {new_tree.(boxes,Map),b} end},
  "merklemap" =>
    {fn {t,b} -> Drtree.query(t,b)
  end,
  before_scenario: fn b -> {new_tree.(boxes,MerkleMap),b} end},

}, inputs: %{
  yellow() <> "1x1"<> cyan() <> " box query" <> reset() => [{0,1},{0,1}],
  yellow() <> "10x10"<> cyan() <> " box query" <> reset() => [{0,10},{0,10}],
  yellow() <> "100x100"<> cyan() <> " box query" <> reset() => [{-50,50},{0,100}],
  yellow() <> "world"<> cyan() <> " box query" <> reset() => [{-180,180},{-90,90}]
})