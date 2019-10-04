defmodule BoundingBoxGenerator do
  @moduledoc false
  require Logger
  import IO.ANSI
  def generate(n,size,result)do
    s = size/2
    x = Enum.random(-180..180)
    y = Enum.random(-90..90)
    if n > 0, do: generate(n - 1, size, [[{x-s,x+s},{y-s,y+s}]] ++ result), else: result
  end

  def single(pos,size)do
    s = size
    x = pos[:x]
    y = pos[:y]
    [[{x-s,x+s},{y-s,y+s}]]
  end

  def gen_and_format(n,size,file)do

    write = fn f ->
      content = generate(n,size,[])
                |> Enum.with_index
                |> Enum.map(fn {x,i} ->
                  "t = t |> ElixirRtree.insert(#{{i,x} |> Kernel.inspect})"
                end)
                |> Enum.join("\n")
                File.write(file,content)
                File.close(f)
    end

    case get_fd(file)do
      {:ok,fd} -> write.(fd)
      {:error,:untouchable} = e -> IO.inspect "#{e} - Impossible to touch file"
      {:error,e} -> IO.inspect "#{e} - Error"
    end

  end

  defp get_fd(file)do
    case File.open(file) do
      {:ok, _fd} = s -> s
      {:error, :enoent} ->
        if File.touch(file) == :ok,do: get_fd(file), else: {:error,:untouchable}
      {:error,_} = e -> e

    end
  end

  def struggle_tree(n,size)do

    boxes = generate(n,size,[]) |> Enum.with_index
    t = Drtree.new
    t1 = :os.system_time(:microsecond)
    tree = boxes |> Enum.reduce(t,fn {b,i},acc ->
      acc |> ElixirRtree.insert({i,b})
    end)
    time = :os.system_time(:microsecond) - t1
    IO.inspect "#{time}"
    tree
  end

  def struggle_updates(mytree,n,size)do

    boxes = generate(n,size,[])
    t1 = :os.system_time(:microsecond)
    tree = boxes |> Enum.reduce(mytree,fn b,acc ->
      acc |> ElixirRtree.update_leaf(Enum.random(0..n),b)
    end)
    t2 = :os.system_time(:microsecond)
    Logger.warn(cyan<>"["<>color(195)<>"Update"<>cyan<>"]"<>yellow<>" #{n}"<>cyan<>" leafs took "<>yellow<>"#{t2-t1} µs")
    tree
  end



end
