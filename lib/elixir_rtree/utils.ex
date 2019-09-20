defmodule ElixirRtree.Utils do
  @moduledoc false

  def format_bbox([{min_x,max_x} = x,{min_y,max_y} = y])do
    %{
      x: x,
      y: y,
      xm: min_x,
      xM: max_x,
      ym: min_y,
      yM: max_y
    }
  end

  def ets_value([raw],atom)do
    case atom do
      :bbox -> raw |> elem(1)
      :daddy -> raw |> elem(2)
      :type -> raw |> elem(3)
    end
  end

  def ets_index(atom)do
    case atom do
      :bbox -> 1
      :daddy -> 2
      :type -> 3
    end
  end

  def combine(box1,box2)do
    a = box1 |> format_bbox
    b = box2 |> format_bbox
    xm = if a.xm < b.xm, do: a.xm, else: b.xm
    xM = if a.xM > b.xM, do: a.xM, else: b.xM
    ym = if a.ym < b.ym, do: a.ym, else: b.ym
    yM = if a.yM > b.yM, do: a.yM, else: b.yM
    result = [{xm,xM},{ym,yM}]
    result = if area(box1) === 0, do: box2, else: result
    if area(box2) === 0, do: box1, else: result
  end

  def area([{a,b},{c,d}])do
    (b - a) * (d - c)
  end


end
