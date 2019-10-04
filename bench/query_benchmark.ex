import IO.ANSI
generate = fn n,s ->
  BoundingBoxGenerator.generate(n,s,[]) |> Enum.map(fn x -> {x,ElixirRtree.Node.new()} end)
end

new_tree = fn boxes,s ->
  boxes |> Enum.slice(0..s-1) |> Enum.reduce(Drtree.new,fn {b,i},acc ->
    acc |> ElixirRtree.insert({i,b})
  end)
end

boxes = generate.(100000,1)

Benchee.run(%{
  cyan() <>"tree "<> cyan() <>"["<> color(195) <>"1000 leafs"<> cyan() <>"]" <> reset() =>
  {fn {t,b} ->
      ElixirRtree.query(t,b)
  end,
  before_scenario: fn b -> {new_tree.(boxes,1000),b} end},
  cyan() <>"tree "<> cyan() <>"["<> color(195) <>"10000 leafs"<> cyan() <>"]" <> reset() =>
  {fn {t,b} ->
      ElixirRtree.query(t,b)
  end,
  before_scenario: fn b -> {new_tree.(boxes,10000),b} end},
  cyan() <>"tree "<> cyan() <>"["<> color(195) <>"100000 leafs"<> cyan() <>"]" <> reset() =>
    {fn {t,b} ->
        ElixirRtree.query(t,b)
  end,
  before_scenario: fn b -> {new_tree.(boxes,100000),b} end},

}, inputs: %{
  yellow() <> "1x1"<> cyan() <> " box query" => [{0,1},{0,1}],
  yellow() <> "10x10"<> cyan() <> " box query" => [{0,10},{0,10}],
  yellow() <> "100x100"<> cyan() <> " box query" => [{-50,50},{0,100}],
  yellow() <> "world"<> cyan() <> " box query" => [{-180,180},{-90,90}]
})