defmodule ElixirRtree do
  alias ElixirRtree.Node
  alias ElixirRtree.Utils

  def new(width \\ 6)do
    w = [{:min_width,:math.floor(width) / 2.0},{:max_width,width}]
    ets = :ets.new(:rtree,[:set])

    node = Node.new()

    tree = %{
      :metadata => %{params: w, ets_table: ets},
      'root' => node,
      node => []
    }

    :ets.insert(ets,{:metadata,Map.get(tree,:metadata)})
    :ets.insert(ets,{'root', node ,:root})
    :ets.insert(ets,{node,[{0,0},{0,0}],:node})
    tree
  end

  def insert(tree,{id,box} = leaf)do
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
      IO.inspect path
      insertion(rbundle,path,leaf)
      |> recursive_update(tl(path),leaf)
    end
  end

  def get_root(rbundle)do
    rbundle.tree |> Map.get('root')
  end

  def is_root?(rbundle,node)do
    get_root(rbundle) == node
  end

  def best_subtree(rbundle,leaf)do
    find_best_subtree(rbundle,get_root(rbundle),leaf,[])
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

      #TODO: valorar q todos son area 0 (que no cae en ninguno existente, entonces eliges el que menos se tenga q estirar)
      best_fit = childs |> Enum.reduce_while([],fn c,acc ->
        cbox = rbundle.ets |> :ets.lookup(c) |> Utils.ets_value(:bbox)
        new_acc = acc ++ [Utils.overlap_area(box,cbox)]
        n_c = length(new_acc)
        if Enum.sum(new_acc) >= 100/n_c, do: {:halt, ind.(new_acc)}, else: if n_c < n_childs, do: {:cont, new_acc}, else: {:halt,ind.(new_acc)}
      end)

      find_best_subtree(rbundle,childs |> Enum.at(best_fit),leaf,[root] ++ track)
    else
      if type === :leaf, do: track, else: [root] ++ track
    end
  end

  def insertion(rbundle,branch,{id,box} = leaf)do

    tree_update = add_entry(rbundle,hd(branch),leaf)

    childs = tree_update |> Map.get(hd(branch))

    final_tree = if length(childs) > rbundle.max_width do
      handle_overflow(%{rbundle | tree: tree_update},branch)
    else
      tree_update
    end

    %{
      tree: final_tree,
      max_width: rbundle.max_width,
      min_width: rbundle.min_width,
      ets: rbundle.ets
    }
  end

  def recursive_update(rbundle,path,{_id,box} = leaf)when length(path) > 0 do

    update_node_bbox(rbundle.ets,hd(path),box)

    if length(path) > 1, do: recursive_update(rbundle,tl(path),leaf), else: rbundle.tree
  end

  def recursive_update(rbundle,_path,_leaf)do
    rbundle.tree
  end

  def update_node_bbox(ets,node,added_box)do
    node_box = ets |> :ets.lookup(node) |> Utils.ets_value(:bbox)
    ets |> :ets.update_element(node,{Utils.ets_index(:bbox),Utils.combine(node_box,added_box)})
  end

  def update_crush(ets,node,{pos,value} = val)do
    ets |> :ets.update_element(node,val)
  end

  def add_entry(rbundle,node,{id,box} = _leaf)do
    :ets.insert(rbundle.ets,{id,box,:leaf})
    update_node_bbox(rbundle.ets,node,box)
    rbundle.tree
    |> Map.update!(node,fn ch -> [id] ++ ch end)
    |> Map.put(id,:leaf)
  end

  def handle_overflow(rbundle,branch)do
    n = hd(branch)

    {node_n,new_node} = split(rbundle,n)

    if is_root?(rbundle,n) do
      new_root = Node.new()
      :ets.insert(rbundle.ets,{new_root,Utils.combine_multiple([node_n.bbox,new_node.bbox]),:node})
      update_crush(rbundle.ets,n,{Utils.ets_index(:bbox),node_n.bbox})
      :ets.insert(rbundle.ets,{new_node.id,new_node.bbox,:node})

      rbundle.tree |> Map.put(new_node.id,new_node.childs)
      |> Map.replace!(n,node_n.childs)
      |> Map.replace!('root',new_root)
      |> Map.put(new_root,[node_n.id,new_node.id])
    else
      parent = hd(tl(branch))
      update_crush(rbundle.ets,n,{Utils.ets_index(:bbox),node_n.bbox})
      :ets.insert(rbundle.ets,{new_node.id,new_node.bbox,:node})

      updated_tree = rbundle.tree
      |> Map.put(new_node.id,new_node.childs)
      |> Map.replace!(n,node_n.childs)
      |> Map.update!(parent,fn ch -> [new_node.id] ++ ch end)


      if length(updated_tree |> Map.get(parent)) > rbundle.max_width, do: handle_overflow(%{rbundle | tree: updated_tree},tl(branch)), else: updated_tree
    end

  end

  def split(rbundle,node)do
    sorted_nodes = rbundle.tree
                   |> Map.get(node)
                   |> Enum.map(fn n ->
                        bbox = rbundle.ets |> :ets.lookup(n) |> Utils.ets_value(:bbox)
                        {bbox |> Utils.middle_value,n,bbox}
                    end)
                   |> Enum.sort
                   |> Enum.map(fn {_x,y,z} -> {y,z} end)

    {n_id,n_bbox} = sorted_nodes
                 |> Enum.slice(0..((rbundle.max_width/2) - 1 |> Kernel.trunc)) |> Enum.unzip


    {dn_id,dn_bbox} = sorted_nodes
                  |> Enum.slice(((rbundle.max_width/2) |> Kernel.trunc)..length(sorted_nodes) - 1) |> Enum.unzip
    IO.inspect n_id
    IO.inspect dn_id
    {%{id: node, childs: n_id, bbox: n_bbox |> Utils.combine_multiple},
      %{id: Node.new(), childs: dn_id, bbox: dn_bbox |> Utils.combine_multiple}}
  end
end
