defmodule BoundingBoxGenerator do
  @moduledoc false

  def generate(n,size,result)do
    s = size/2
    x = Enum.random(-180..180)
    y = Enum.random(-90..90)
    new_result = [[{x-s,x+s},{y-s,y+s}]] ++ result
    if n > 0, do: generate(n - 1, size, new_result), else: new_result
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


end
