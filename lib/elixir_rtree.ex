defmodule ElixirRtree do

  alias ElixirRtree.Utils

  def new(width \\ 6)do
    w = [{:min_width,:math.floor(width) / 2.0},{:max_width,width}]
    ets = :ets.new(:rtree,[:set])

    tree = %{
      :metadata => %{params: w, ets_table: ets},
      'root' => []
    }

    :ets.insert(ets,{:metadata,Map.get(tree,:metadata)})
    :ets.insert(ets,{'root', [{0,0},{0,0}],nil,:root})
    tree
  end

  def insert(tree,{_box,id} = leaf)do
    meta = tree[:metadata]
    params = meta.params

    if meta[:ets_table] |> :ets.member(id) do
      IO.inspect "Impossible to insert, id value already exists: id's MUST be uniq"
      tree
    else
      rbundle = %{
        tree: tree,
        max_width: params[:max_width],
        min_width: params[:min_width],
        ets: meta.ets_table
      }
      path = best_subtree(rbundle,leaf)
      insert_leaf(rbundle,hd(path),leaf)
      |> recursive_update(tl(path),leaf)
    end
  end

  def best_subtree(rbundle,leaf)do
    find_best_subtree(rbundle,'root',leaf,[])
  end

  def find_best_subtree(rbundle,root,{_id,box} = leaf,track)do
    childs = rbundle.tree |> Map.get(root)
    type = rbundle.ets |> :ets.lookup(root) |> Utils.ets_value(:type)

    if is_list(childs) and length(childs) > 0 do
      n_childs = length(childs)
      # TODO: mover de aquí para q no se redefina todo el rato
      ind = fn l ->
        m = Enum.max(l)
        l |> Enum.find_index(fn e -> e == m end)
      end

      best_fit = childs |> Enum.reduce_while([],fn c,acc ->
        cbox = rbundle.ets |> :ets.lookup(c) |> Utils.ets_value(:bbox)
        new_acc = acc ++ [Utils.overlap_area(box,cbox)]
        n_c = length(new_acc)
        if Enum.sum(new_acc) >= 100/n_c, do: {:halt, ind.(new_acc)}, else: if n_c < n_childs, do: {:cont, new_acc}, else: {:halt,ind.(new_acc)}
      end)

      find_best_subtree(rbundle,childs |> Enum.at(best_fit),leaf,track ++ [root])
    else
      if type === :leaf, do: track, else: track ++ [root]
    end
  end

  def insert_leaf(rbundle,node,{id,box} = _leaf)do

    childs = rbundle.tree |> Map.get(node)

    res = if length(childs) < rbundle.max_width do
      :ets.insert(rbundle.ets,{id,box,node,:leaf})
      update_node_bbox(rbundle.ets,node,box)
      rbundle.tree
      |> Map.update!(node,fn ch -> [id] ++ ch end)
      |> Map.put(id,:leaf)
    else
      IO.inspect "Im fking overflowing somewhere"
      rbundle.tree
    end

    %{
      tree: res,
      max_width: rbundle.max_width,
      min_width: rbundle.min_width,
      ets: rbundle.ets
    }
  end

  def recursive_update(rbundle,path,{_id,box} = leaf)when length(path) > 0 do

    update_node_bbox(rbundle.ets,hd(path),box)

    if length(path) > 1, do: recursive_update(rbundle,tl(path),leaf), else: true
  end

  def recursive_update(rbundle,_path,_leaf)do
    rbundle.tree
  end

  def update_node_bbox(ets,node,added_box)do
    node_box = ets |> :ets.lookup(node) |> Utils.ets_value(:bbox)
    ets |> :ets.update_element(node,{Utils.ets_index(:bbox) + 1,Utils.combine(node_box,added_box)})
  end

end
