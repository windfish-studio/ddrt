defmodule ElixirRtree do


  def new(width \\ 6)do
    w = [{:min_width,:math.floor(width) / 2.0},{:max_width,width}]
    ets = :ets.new(:rtree,[:set])

    tree = %{
      :metadata => %{params: w, ets_table: ets},
      'root' => []
    }

    :ets.insert(ets,{:metadata,Map.get(tree,:metadata)})
    :ets.insert(ets,{'root',
                    {Map.get(tree,'root'),[{:x,{0,0}},{:y,{0,0}}]}
                })
    tree
  end

  def insert(tree,{box,id} = leaf)do
    meta = tree[:metadata]
    params = meta[:params]

    recursive_insertion(%{
      tree: tree,
      max_width: params[:max_width],
      min_width: params[:min_width],
      ets: meta[:ets_table]
    },'root',id)

  end

  def recursive_insertion(rbundle,key,leaf)do

    childs = rbundle.tree |> Map.get(key)
    available_space = rbundle.max_width - length(childs)
    tree_update = case available_space do
      x when x > 0 -> rbundle.tree |> Map.update!(key,fn ch -> [leaf.id] ++ ch end)
      _ -> IO.puts "Merge"
    end

    tree_update
  end



end
