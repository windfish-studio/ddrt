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

  # Combine two bounding boxes into one
  def combine(box1,box2)do
    a = box1 |> format_bbox
    b = box2 |> format_bbox
    xm = Kernel.min(a.xm,b.xm)
    xM = Kernel.max(a.xM,b.xM)
    ym = Kernel.min(a.ym,b.ym)
    yM = Kernel.max(a.yM,b.yM)
    result = [{xm,xM},{ym,yM}]
    result = if area(box1) === 0, do: box2, else: result
    if area(box2) === 0, do: box1, else: result
  end

  # Returns de percent of the overlap area between box1 and box2
  def overlap_area(box1,box2)do
    a = box1 |> format_bbox
    b = box2 |> format_bbox
    x_overlap = Kernel.max(0,Kernel.min(a.xM,b.xM) - Kernel.max(a.xm,b.xm))
    y_overlap = Kernel.max(0,Kernel.min(a.yM,b.yM) - Kernel.max(a.ym,b.ym))
    (x_overlap * y_overlap) * 100 |> Kernel.trunc
  end

  # Return the area of a bounding box
  def area([{a,b},{c,d}])do
    (b - a) * (d - c)
  end


end
