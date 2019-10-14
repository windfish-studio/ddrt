import IO.ANSI

Drtree.start_link(%{})
generate = fn n,s ->
  BoundingBoxGenerator.generate(n,s,[]) |> Enum.map(fn x -> {UUID.uuid1(),x} end)
end

new_tree = fn boxes,typ ->
  Drtree.new(%{type: typ})
  Drtree.insert(boxes)
end

boxes = generate.(10000,1)

Benchee.run(%{
  "map" =>
  {fn b -> Drtree.query(b)
  end,
  before_scenario: fn b ->
                      new_tree.(boxes,Map)
                      b end},
  "merklemap" =>
    {fn b -> Drtree.query(b)
  end,
  before_scenario: fn b ->
                      new_tree.(boxes,MerkleMap)
                      b end},

}, inputs: %{
  yellow() <> "1x1"<> cyan() <> " box query" <> reset() => [{0,1},{0,1}],
  yellow() <> "10x10"<> cyan() <> " box query" <> reset() => [{0,10},{0,10}],
  yellow() <> "100x100"<> cyan() <> " box query" <> reset() => [{-50,50},{0,100}],
  yellow() <> "world"<> cyan() <> " box query" <> reset() => [{-180,180},{-90,90}]
})