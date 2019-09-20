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
    :ets.insert(ets,{'root', [{0,0},{0,0}],nil,:node})
    tree
  end

  def insert(tree,{_box,id} = leaf)do
    meta = tree[:metadata]
    params = meta.params

    if meta[:ets_table] |> :ets.member(id) do
      IO.inspect "Impossible to insert, id value already exists: id's MUST be uniq"
      tree
    else
      recursive_insertion(%{
        tree: tree,
        max_width: params[:max_width],
        min_width: params[:min_width],
        ets: meta.ets_table
      },'root',leaf)
    end
  end

  def recursive_insertion(rbundle,key,{box,id})do

    :ets.insert(rbundle.ets,{id,box,key,:leaf})
    childs = rbundle.tree |> Map.get(key)
    n_childs = length(childs)
    if n_childs == 0 or rbundle.tree |> Map.get(childs |> List.first) |> (fn x -> x === :leaf end).() do
      dad_box = rbundle.ets |> :ets.lookup(key) |> Utils.ets_value(:bbox)
      available_space = rbundle.max_width - length(childs)
      case available_space do
        x when x > 0 -> rbundle.ets |> :ets.update_element(key,{Utils.ets_index(:bbox) + 1,Utils.combine(dad_box,box)})
                        rbundle.tree
                        |> Map.update!(key,fn ch -> [id] ++ ch end)
                        |> Map.put(id,:leaf)
        _ -> init_merge_childs(childs,rbundle.ets)
      end
    end
  end

  def init_merge_childs(childs,ets)do
    fc = hd(childs)
    cbox = ets |> :ets.lookup(fc) |> Utils.ets_value(:bbox) |> Utils.format_bbox
    r = %{
      xm: cbox.xm,
      xM: cbox.xM,
      ym: cbox.ym,
      yM: cbox.yM
    }
    if length(childs) > 1, do: merge_childs(tl(childs),ets,r), else: r
  end

  defp merge_childs(childs,ets,result)do
    c = hd(childs)
    cbox = ets |> :ets.lookup(c) |> Utils.ets_value(:bbox) |> Utils.format_bbox

    new_xm = if cbox.xm < result.xm, do: cbox.xm, else: result.xm
    new_xM = if cbox.xM > result.xM, do: cbox.xM, else: result.xM
    new_ym = if cbox.ym < result.ym, do: cbox.ym, else: result.ym
    new_yM = if cbox.yM > result.yM, do: cbox.yM, else: result.yM
    r = [{new_xm,new_xM},{new_ym,new_yM}]
    if length(childs) > 1, do: merge_childs(tl(childs),ets, r |> Utils.format_bbox), else: r
  end
end
