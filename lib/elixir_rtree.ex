defmodule ElixirRtree do
  alias ElixirRtree.Node
  alias ElixirRtree.Utils
  require Logger
  import IO.ANSI

  # Entre 1 y 64800. Bigger value => ^ updates speed, ~v query speed.
  @max_area 20000

  def new(opts)do
    ets = :ets.new(:rtree,[:set,opts[:access]])
    db = if opts[:database], do: setup_dgraph
    if opts[:verbose], do: Logger.configure([{:level,:debug}]), else: Logger.configure([{:level,:warn}])

    {f,s} = :rand.seed(:exrop,opts[:seed])
    {node,new_ticket} = Node.new(f,s)

    tree = %{
      :metadata => %{params: opts, ets_table: ets, dgraph: db, seeding: f},
      :ticket => new_ticket,
      :parents => %{},
      'root' => node,
       node => []
    }

    :ets.insert(ets,{:metadata,Map.get(tree,:metadata)})
    :ets.insert(ets,{'root', node ,:root})
    :ets.insert(ets,{node,[{0,0},{0,0}],:node})

    if db do
      root = %{
        "identifier" => "root",
        "childs" => [%{"identifier" => node,
                    "bounding" => Kernel.inspect([{0,0},{0,0}],charlists: false),
                    "childs" => []}]
      }

      Dlex.set(db,root)
    end

    tree
  end

  def setup_dgraph()do
    {:ok, pid} = Dlex.start_link(pool_size: 2)
    Dlex.alter!(pid, %{drop_all: true})

    schema = """
      <identifier>: string @index(hash) .
    """

    Dlex.alter!(pid, schema)
    pid
  end

  # Helpers

  def get_root(rbundle)do
    rbundle.tree |> Map.get('root')
  end

  def is_root?(rbundle,node)do
    get_root(rbundle) == node
  end

  def get_rbundle(tree)do
    meta = tree[:metadata]
    params = meta.params
    rbundle = %{
      tree: tree,
      width: params[:width],
      verbose: params[:verbose],
      type: params[:type],
      ets: meta.ets_table,
      db: meta.dgraph,
      parents: tree[:parents],
      seeding: meta[:seeding]
    }
  end

  # Actions

  def insert(tree,{id,box} = leaf)do
    rbundle = get_rbundle(tree)
    if rbundle.ets |> :ets.member(id) do
      if rbundle.verbose,do: Logger.debug(cyan() <>"["<>green<>"Insertion"<>cyan()<>"] failed:" <> yellow() <> " [#{id}] " <> cyan() <> "already exists at tree." <> yellow() <> " [Tip]"<> cyan() <> " use " <> yellow() <>"update_leaf/3")
      tree
    else
      path = best_subtree(rbundle,leaf)
      t1 = :os.system_time(:microsecond)
      r = insertion(rbundle,path,leaf)
      |> recursive_update(tl(path),leaf,:insertion)
      t2 = :os.system_time(:microsecond)
      if rbundle.verbose,do: Logger.debug(cyan() <>"["<>green<>"Insertion"<>cyan()<>"] success: "<> yellow() <> "[#{id}]" <> cyan() <> " was inserted at" <> yellow() <>" ['#{hd(path)}']")
      if rbundle.verbose,do: Logger.info(cyan() <>"["<>green<>"Insertion"<>cyan()<>"] took" <> yellow() <> " #{t2-t1} µs")
      r
    end
  end

  def query(tree,box)do
    rbundle = get_rbundle(tree)
    t1 = :os.system_time(:microsecond)
    r = find_match_leafs(rbundle,box,[get_root(rbundle)],[],[])
    t2 = :os.system_time(:microsecond)
    if rbundle.verbose,do: Logger.info(cyan() <> "["<>color(201)<>"Query"<>cyan()<>"] box " <> yellow() <> "#{box |> Kernel.inspect} " <> cyan() <> "took " <> yellow() <> "#{t2-t1} µs")
    r
  end

  def delete(tree,id)do
    rbundle = get_rbundle(tree)
    t1 = :os.system_time(:microsecond)
    r = if rbundle.ets |> :ets.member(id) do
      remove(rbundle,id)
    else
      tree
    end
    t2 = :os.system_time(:microsecond)
    if rbundle.verbose,do: Logger.info(cyan() <>"["<>color(124)<>"Delete"<>cyan()<>"] leaf "<>yellow()<>"[#{id}]"<>cyan()<>" took "<>yellow()<>"#{t2-t1} µs")
    r
  end

  def update_leaf(tree,id,{old_box,new_box} = boxes)do
    rbundle = get_rbundle(tree)
    if rbundle.ets |> :ets.member(id) do
      t1 = :os.system_time(:microsecond)
      r = update(rbundle,id,boxes)
      t2 = :os.system_time(:microsecond)
      if rbundle.verbose,do: Logger.info(cyan()<>"["<>color(195)<>"Update"<>cyan()<>"] "<>yellow()<>"[#{id}]"<>cyan()<>" from "<>yellow()<>"#{old_box |> Kernel.inspect}"<>cyan()<>" to "<>yellow()<>"#{new_box |> Kernel.inspect}"<>cyan()<>" took "<>yellow()<>"#{t2-t1} µs")
      r
    else
      if rbundle.verbose,do: Logger.warn(cyan()<>"["<>color(195)<>"Update"<>cyan()<>"] "<>yellow()<>"[#{id}] doesn't exists"<>cyan())
      tree
    end
  end

  # You dont need to know old_box but is a BIT slower
  def update_leaf(tree,id,new_box)do
    rbundle = get_rbundle(tree)
    update_leaf(tree,id,{rbundle.ets |> :ets.lookup(id) |> Utils.ets_value(:bbox),new_box})
  end

  # Executes the entire tree
  def execute(tree)do
    rbundle = get_rbundle(tree)
    rbundle.ets |> :ets.delete
  end
  # Internal actions
  ## Insert

  # triple - S (Structure Swifty Shift)
  def triple_s(rbundle,old_node,new_node,{id,box})do
    if rbundle.db do
      Dlex.transaction(rbundle.db, fn conn ->
        query = ~s|{ v as var(func: eq(identifier, "#{old_node}"))
                      x as var(func: eq(identifier, "#{id}"))}|
        Dlex.delete(rbundle.db, query,
          ~s|uid(v) <childs> uid(x) .|,return_json: true)

        query = ~s|{ v as var(func: eq(identifier, "#{new_node}"))
                      x as var(func: eq(identifier, "#{id}"))}|
        Dlex.mutate!(rbundle.db, query,
          ~s|uid(v) <childs> uid(x) .|,return_json: true)
      end)
    end

    parents_update = rbundle.parents |> Map.put(id,new_node)
    old_node_childs_update = rbundle.tree |> Map.get(old_node) |> (fn n -> n -- [id] end).()
    tree_update = rbundle.tree
                  |> Map.update!(new_node, fn ch -> [id] ++ ch end)
                  |> Map.put(:parents,parents_update)

    r = if length(old_node_childs_update) > 0 do
      %{rbundle | tree: tree_update |> Map.put(old_node,old_node_childs_update) , parents: parents_update} |> recursive_update(old_node,box,:deletion)
    else
      %{rbundle | tree: tree_update, parents: parents_update} |> remove(old_node)
    end
  end

  defp insertion(rbundle,branch,{id,box} = leaf)do

    tree_update = add_entry(rbundle,hd(branch),leaf)

    childs = tree_update |> Map.get(hd(branch))

    final_tree = if length(childs) > rbundle.width do
      handle_overflow(%{rbundle | tree: tree_update, parents: tree_update |> Map.get(:parents)},branch)
    else
      tree_update
    end

    %{rbundle | tree: final_tree}
  end

  defp add_entry(rbundle,node,{id,box} = _leaf)do
    :ets.insert(rbundle.ets,{id,box,:leaf})
    update_node_bbox(rbundle,node,box,:insertion)

    if rbundle.db do
      query = ~s|{ v as var(func: eq(identifier, "#{node}")) }|
      Dlex.mutate!(rbundle.db, query,
        ~s|uid(v) <childs> _:blank .
         _:blank <identifier> "#{id}" .
         _:blank <bounding> "#{Kernel.inspect(box,charlists: false)}" .|,return_json: true)
    end
    parents_update = rbundle.parents |> Map.put(id,node)

    rbundle.tree
    |> Map.update!(node,fn ch -> [id] ++ ch end)
    |> Map.put(:parents,parents_update)
    |> Map.put(id,:leaf)
  end

  defp handle_overflow(rbundle,branch)do
    n = hd(branch)

    {node_n,new_node} = split(rbundle,n)

    treeck = rbundle.tree |> Map.put(:ticket,new_node.next_ticket)

    if is_root?(rbundle,n) do
      {new_root,ticket} = Node.new(rbundle.seeding,treeck |> Map.get(:ticket))
      treeck = treeck |> Map.put(:ticket,ticket)
      :ets.update_element(rbundle.ets,'root',{Utils.ets_index(:bbox),new_root})
      root_bbox = Utils.combine_multiple([node_n.bbox,new_node.bbox])
      :ets.insert(rbundle.ets,{new_root,root_bbox,:node})
      update_crush(rbundle,n,{Utils.ets_index(:bbox),node_n.bbox})
      :ets.insert(rbundle.ets,{new_node.id,new_node.bbox,:node})

      if rbundle.db do
        Dlex.transaction(rbundle.db, fn conn ->
          query = ~s|{ v as var(func: eq(identifier, "root"))
                      x as var(func: eq(identifier, "#{node_n.id}"))}|
          Dlex.delete(rbundle.db, query,
            ~s|uid(v) <childs> uid(x) .|,return_json: true)

          query = ~s|{ v as var(func: eq(identifier, "root"))}|
          Dlex.mutate!(rbundle.db, query,
            ~s|uid(v) <childs> _:blank .
            _:blank <identifier> "#{new_root}".
            _:blank <bounding> "#{root_bbox |> Kernel.inspect(charlists: false)}" .|,return_json: true)

          query = ~s|{ v as var(func: eq(identifier, "#{new_root}"))
                      x as var(func: eq(identifier, ["#{node_n.id}","#{new_node.id}"]))}|
          Dlex.mutate!(rbundle.db, query,
            ~s|uid(v) <childs> uid(x) .|,return_json: true)
        end)
      end
      parents_update = rbundle.parents
                       |> Map.put(node_n.id,new_root)
                       |> Map.put(new_node.id,new_root)
      parents_update = new_node.childs |> Enum.reduce(parents_update,fn c,acc ->
        acc |> Map.put(c,new_node.id)
      end)
      treeck |> Map.put(new_node.id,new_node.childs)
      |> Map.replace!(n,node_n.childs)
      |> Map.replace!('root',new_root)
      |> Map.put(new_root,[node_n.id,new_node.id])
      |> Map.put(:parents,parents_update)
    else
      parent = hd(tl(branch))
      update_crush(rbundle,n,{Utils.ets_index(:bbox),node_n.bbox})
      :ets.insert(rbundle.ets,{new_node.id,new_node.bbox,:node})
      if rbundle.db do
        query = ~s|{ v as var(func: eq(identifier, "#{parent}"))
                    x as var(func: eq(identifier, "#{new_node.id}"))}|
        Dlex.mutate!(rbundle.db, query,
          ~s|uid(v) <childs> uid(x) .|,return_json: true)
      end
      parents_update = rbundle.parents |> Map.put(new_node.id,parent)
      parents_update = new_node.childs |> Enum.reduce(parents_update,fn c,acc ->
        acc |> Map.put(c,new_node.id)
      end)
      updated_tree = treeck
                     |> Map.put(new_node.id,new_node.childs)
                     |> Map.put(:parents,parents_update)
                     |> Map.replace!(n,node_n.childs)
                     |> Map.update!(parent,fn ch -> [new_node.id] ++ ch end)

      if length(updated_tree |> Map.get(parent)) > rbundle.width, do: handle_overflow(%{rbundle | tree: updated_tree, parents: parents_update},tl(branch)), else: updated_tree
    end
  end

  defp split(rbundle,node)do

    sorted_nodes = rbundle.tree
                   |> Map.get(node)
                   |> Enum.map(fn n ->
                      bbox = rbundle.ets |> :ets.lookup(n) |> Utils.ets_value(:bbox)
                      {bbox |> Utils.middle_value,n,bbox}
                    end)
                   |> Enum.sort
                   |> Enum.map(fn {_x,y,z} -> {y,z} end)

    {n_id,n_bbox} = sorted_nodes
                    |> Enum.slice(0..((rbundle.width/2) - 1 |> Kernel.trunc)) |> Enum.unzip

    {dn_id,dn_bbox} = sorted_nodes
                      |> Enum.slice(((rbundle.width/2) |> Kernel.trunc)..length(sorted_nodes) - 1) |> Enum.unzip

    {new_node,next_ticket} = Node.new(rbundle.seeding,rbundle.tree |> Map.get(:ticket))
    n_bounds = n_bbox |> Utils.combine_multiple
    dn_bounds = dn_bbox |> Utils.combine_multiple
    if rbundle.db do
      Dlex.set(rbundle.db,%{
        "identifier" => new_node,
        "bounding" => "#{dn_bounds |> Kernel.inspect(charlists: false)}",
        "childs" => []
      })

      Dlex.transaction(rbundle.db, fn conn ->

        query = ~s|{ v as var(func: eq(identifier, "#{node}"))
                    c as var(func: eq(identifier, #{dn_id |> Kernel.inspect(charlists: false)}))}|
        Dlex.delete(rbundle.db, query,
          ~s|uid(v) <childs> uid(c) .
             uid(v) <bounding> "#{n_bounds |> Kernel.inspect(charlists: false)}" .|,return_json: true)


        query = ~s|{ v as var(func: eq(identifier, "#{new_node}"))
                    c as var(func: eq(identifier, #{dn_id |> Kernel.inspect(charlists: false)}))}|
        Dlex.mutate!(rbundle.db, query,
          ~s|uid(v) <childs> uid(c) .|,return_json: true)
      end)
    end

    {%{id: node, childs: n_id, bbox: n_bounds},
      %{id: new_node, childs: dn_id, bbox: dn_bounds, next_ticket: next_ticket}}
  end

  defp best_subtree(rbundle,leaf)do
    r = find_best_subtree(rbundle,get_root(rbundle),leaf,[])
  end

  defp find_best_subtree(rbundle,root,{_id,box} = leaf,track)do
    childs = rbundle.tree |> Map.get(root)
    type = rbundle.ets |> :ets.lookup(root) |> Utils.ets_value(:type)

    if is_list(childs) and length(childs) > 0 do
      winner = get_best_candidate(rbundle,childs,box)
      new_track = [root] ++ track
      find_best_subtree(rbundle,winner,leaf,new_track)
    else
      if type === :leaf, do: track, else: [root] ++ track
    end
  end

  defp get_best_candidate(rbundle,candidates,box)do
    win_entry = candidates |> Enum.reduce_while(%{id: :not_id,cost: :infinity},fn c,acc ->
      cbox = rbundle.ets |> :ets.lookup(c) |> Utils.ets_value(:bbox)
      if Utils.contained?(cbox,box)do
        {:halt, %{id: c, cost: 0}}
      else
        enlargement = Utils.enlargement_area(cbox,box)
        if enlargement < acc |> Map.get(:cost) do
          {:cont, %{id: c, cost: enlargement}}
        else
          {:cont, acc}
        end
      end
    end)
    win_entry[:id]
  end

  ## Query

  defp find_match_leafs(rbundle,box,dig,leafs,flood)do
    f = hd(dig)
    tail = if length(dig) > 1, do: tl(dig), else: []
    fbox = rbundle.ets |> :ets.lookup(f) |> Utils.ets_value(:bbox)

    {new_dig,new_leafs,new_flood} = if Utils.overlap?(fbox,box)do
        content = rbundle.tree |> Map.get(f)
        if is_atom(content) do
          {tail,[f] ++ leafs,flood}
        else
          if Utils.contained?(box,fbox), do: {tail,leafs,[f] ++ flood}, else: {content ++ tail,leafs,flood}
        end
      else
        {tail,leafs,flood}
    end

    if length(new_dig) > 0 do
      find_match_leafs(rbundle,box,new_dig,new_leafs,new_flood)
    else
      new_leafs ++ explore_flood(rbundle,new_flood)
    end
  end

  defp explore_flood(rbundle,flood)do
    next_floor = flood |> Enum.flat_map(fn x ->
                                        case rbundle.tree |> Map.get(x) do
                                          :leaf -> []
                                          any -> any
                                        end end)

    if length(next_floor) > 0,do: explore_flood(rbundle,next_floor), else: flood
  end

  ## Delete

  defp remove(rbundle,id)do

    parent = rbundle.parents |> Map.get(id)

    if parent do
      removed_bbox = rbundle.ets |> :ets.lookup(id) |> Utils.ets_value(:bbox)
      rbundle.ets |> :ets.delete(id)
      parents_update = rbundle.parents |> Map.delete(id)
      tree_updated = rbundle.tree |> Map.delete(id)
      |> Map.update!(parent,fn ch -> ch -- [id] end)
      |> Map.put(:parents,parents_update)
      if rbundle.db do
        query = ~s|{ v as var(func: eq(identifier, "#{parent}"))
                    x as var(func: eq(identifier, "#{id}"))}|
        Dlex.delete(rbundle.db, query,
          ~s|uid(v) <childs> uid(x) .|,return_json: true)
      end
      parent_childs = tree_updated |> Map.get(parent)
      if length(parent_childs) > 0 do
        %{rbundle | tree: tree_updated, parents: parents_update} |> recursive_update(parent,removed_bbox,:deletion)
      else
        remove(%{rbundle | tree: tree_updated, parents: parents_update},parent)
      end
    else
      if rbundle.db do
        query = ~s|{ v as var(func: eq(identifier, "#{id}"))}|
        Dlex.mutate!(rbundle.db, query,
          ~s|uid(v) <bounding> "#{[{0,0},{0,0}] |> Kernel.inspect(charlists: false)}" .|,return_json: true)
      end
      rbundle.ets |> :ets.update_element(id,{Utils.ets_index(:bbox),[{0,0},{0,0}]})
      rbundle.tree
    end
  end

  ## Hard update

  defp update(rbundle,id,{old_box,new_box})do

    parent = rbundle.tree |> Map.get(:parents) |> Map.get(id)
    parent_box = rbundle.ets |> :ets.lookup(parent) |> Utils.ets_value(:bbox)

    rbundle |> update_crush(id,{Utils.ets_index(:bbox),new_box})

    r = if Utils.contained?(parent_box,new_box)do
      if Utils.in_border?(parent_box,old_box)do
        if rbundle.verbose,do: Logger.debug(cyan()<>"["<>color(195)<>"Update"<>cyan()<>"] Good case: new box "<>yellow()<>"(#{new_box |> Kernel.inspect})"<>cyan()<>" of "<>yellow()<>"[#{id}]"<>cyan()<>" reduce the parent "<>yellow()<>"(['#{parent}'])"<>cyan()<>" box")
        rbundle |> recursive_update(parent,old_box,:deletion)
      else
        if rbundle.verbose,do: Logger.debug(cyan()<>"["<>color(195)<>"Update"<>cyan()<>"] Best case: new box "<>yellow()<>"(#{new_box |> Kernel.inspect})"<>cyan()<>" of "<>yellow()<>"[#{id}]"<>cyan()<>" was contained by his parent "<>yellow()<>"(['#{parent}'])")
        rbundle.tree
      end
    else
      case rbundle |> node_brothers(parent) |> (fn b -> good_slot?(rbundle,b,new_box) end).() do
        {new_parent,_new_brothers,_new_parent_box} ->
          if rbundle.verbose,do: Logger.debug(cyan()<>"["<>color(195)<>"Update"<>cyan()<>"] Neutral case: new box "<>yellow()<>"(#{new_box |> Kernel.inspect})"<>cyan()<>" of "<>yellow()<>"[#{id}]"<>cyan()<>" increases the parent box but there is an available slot at one uncle "<>yellow()<>"(['#{new_parent}'])")
          triple_s(rbundle,parent,new_parent,{id,old_box})

        nil ->  if Utils.area(parent_box) >= @max_area do
                  if rbundle.verbose,do: Logger.debug(cyan()<>"["<>color(195)<>"Update"<>cyan()<>"] Worst case: new box "<>yellow()<>"(#{new_box |> Kernel.inspect})"<>cyan()<>" of "<>yellow()<>"[#{id}]"<>cyan()<>" increases the parent box which was so big "<>yellow()<>"#{(((Utils.area(parent_box) |> Kernel.trunc)/@max_area) * 100) |> Kernel.trunc } %. "<>cyan()<>"So we proceed to delete "<>yellow()<>"[#{id}]"<>cyan()<>" and reinsert at tree")
                  rbundle |> top_down({id,new_box})
                else
                  if rbundle.verbose,do: Logger.debug(cyan()<>"["<>color(195)<>"Update"<>cyan()<>"] Bad case: new box "<>yellow()<>"(#{new_box |> Kernel.inspect})"<>cyan()<>" of "<>yellow()<>"[#{id}]"<>cyan()<>" increases the parent box which isn't that big yet "<>yellow()<>"#{(((Utils.area(parent_box) |> Kernel.trunc)/@max_area) * 100) |> Kernel.trunc} %. "<>cyan()<>"So we proceed to increase parent "<>yellow()<>"(['#{parent}'])"<>cyan()<>" box")
                  rbundle |> recursive_update(parent,new_box,:insertion)
                end
      end
    end
  end

  ## Common updates

  defp top_down(rbundle,{id,box})do
    rbundle |> remove(id) |> insert({id,box})
  end

  # Recursive bbox updates when you have node path from root (at insertion)
  defp recursive_update(rbundle,path,{_id,box} = leaf,:insertion)when length(path) > 0 do
    modified = update_node_bbox(rbundle,hd(path),box,:insertion)

    if modified and length(path) > 1, do: recursive_update(rbundle,tl(path),leaf,:insertion), else: rbundle.tree
  end

  # Recursive bbox updates when u dont have node path from root, so you have to query parents map... (at delete)
  defp recursive_update(rbundle,node,box,mode)when is_list(node) |> Kernel.not do
    modified = update_node_bbox(rbundle,node,box,mode)
    next = rbundle.parents |> Map.get(node)
    if modified and next, do: recursive_update(rbundle,next,box,mode), else: rbundle.tree
  end

  # Typical dumbass safe method
  defp recursive_update(rbundle,_path,_leaf,:insertion)do
    rbundle.tree
  end

  defp update_node_bbox(rbundle,node,the_box,action)do
    node_box = rbundle.ets |> :ets.lookup(node) |> Utils.ets_value(:bbox)

    new_bbox = case action do
      :insertion -> Utils.combine(node_box,the_box)
      :deletion -> if Utils.in_border?(node_box,the_box) do
                      rbundle.tree |> Map.get(node)
                      |> Enum.map(fn c ->
                        rbundle.ets |> :ets.lookup(c) |> Utils.ets_value(:bbox) end)
                      |> Utils.combine_multiple
                    else
                      node_box
                    end
    end

    bbox_mutation(rbundle,node,new_bbox,node_box)
  end

  defp bbox_mutation(rbundle,node,new_bbox,node_box)do
    if new_bbox == node_box do
      false
    else
      if rbundle.db do
        Dlex.transaction(rbundle.db, fn conn ->
          query = ~s|{ v as var(func: eq(identifier, "#{node}"))}|
          Dlex.mutate!(rbundle.db, query,
            ~s|uid(v) <bounding> "#{new_bbox |> Kernel.inspect(charlists: false)}" .|,return_json: true)
        end)
      end
      rbundle.ets |> :ets.update_element(node,{Utils.ets_index(:bbox),new_bbox})
      true
    end
  end

  # Crush a value, not read needed.
  defp update_crush(rbundle,node,{pos,value} = val)do
    if rbundle.db do
      Dlex.transaction(rbundle.db, fn conn ->
        query = ~s|{ v as var(func: eq(identifier, "#{node}"))}|
        Dlex.mutate!(rbundle.db, query,
          ~s|uid(v) <bounding> "#{value |> Kernel.inspect(charlists: false)}" .|,return_json: true)
      end)
    end
    rbundle.ets |> :ets.update_element(node,val)
  end

  # Return the brothers of the node [{brother_id, brother_childs, brother_box},...]
  defp node_brothers(rbundle,node)do
    parent = rbundle.parents |> Map.get(node)
    rbundle.tree
    |> Map.get(parent)
    |> (fn c -> c -- [node] end).()
    |> Enum.map(fn b -> {b,rbundle.tree |> Map.get(b),rbundle.ets |> :ets.lookup(b) |> Utils.ets_value(:bbox)} end)
  end

  # Find a good slot (at bros/brothers list) for the box, it means that the brother hasnt the max childs and the box is at the limits of his own
  defp good_slot?(rbundle,bros,box)do
    bros |> Enum.find(fn {_bid,bchilds,bbox} -> length(bchilds) < rbundle.width and Utils.contained?(bbox,box) end)
  end

end
