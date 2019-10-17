[![CircleCI](https://circleci.com/gh/windfish-studio/rtree/tree/master.svg?style=svg)](https://circleci.com/gh/windfish-studio/rtree/tree/master)
![LICENSE](https://img.shields.io/hexpm/l/dynamic_rtree)
![VERSION](https://img.shields.io/hexpm/v/dynamic_rtree)
# Dynamic_Rtree
This package is actually composed of 2 main modules:

**DDRT**

This is the top level module, which one you should include at your application supervision tree.


**Drtree**

 This is the API module of the elixir r-tree implementation where you can do the basic actions.


# DDRT

  If you want the distributed dynamic r-tree, start this process is a MUST.
  ```elixir
  DDRT.start_link(%{})
  ```
  or
  ```elixir
  children = [
    ...
    {DDRT, %{}}
  ]
  ```

  Else, if you want just the dynamic r-tree this module is not a MUST, but you can use it anyways.

  ## Configuration

  Let's talk about which parameters you can pass to init the DDRT.

   **name**: the name of the r-tree.

   **mode**: the mode of the r-tree. 
   
   There are two:
   ```elixir
         :dynamic: all the r-trees with same name in different nodes will be sync.

         :standalone: a dynamic r-tree that just will be at your node.
   ```   
  **width**: the max width (the number of childs) than can handle every node.

  **type**: the type of data structure that maintains the r-tree. 
  
  There are two:
  ```elixir
         Map: faster way. Recommended if you don't need sync.

         MerkleMap: a bit slower, but perfect to get minimum r-tree modifications.
  ```
         
  **verbose**: allows `Logger` to report console logs. (Decrease performance)

  **seed**: the start seed for the middle nodes uniq ID of the r-tree. Same seed will always reach same sequence of uniq ID's.

  ## Distributed part

  You have to config the Erlang node interconnection with `libcluster`.

  The easy way is that:
  
   At `config.exs` define the nodes you want to connect:
```elixir
 use Mix.Config
 config :libcluster,
 topologies: [
  example: [
    # The selected clustering strategy. Required.
    strategy: Cluster.Strategy.Epmd,
    # Configuration for the provided strategy. Optional.
    config: [hosts: [:"a@localhost", :"b@localhost"]],
  ]
 ]
```
   Then you should start you application for example like that:
```elixir
eduardo@elixir_rtree $ iex --name a@localhost -S mix
iex(a@localhost)1>

eduardo@elixir_rtree $ iex --name b@localhost -S mix
iex(b@localhost)1>
```

  Finally, if you started in both nodes a `DDRT` with the same name you can simply use the `Drtree` API module and you will have the r-tree sync between nodes.

`Note`: is important that you have the same configuration for the DDRT at the different nodes.

# Drtree

  This is the API module of the elixir r-tree implementation where you can do the basic actions.


  ## Easy to use:

   Starts a local r-tree named as Peter
   ```elixir
   iex> DDRT.start_link(%{name: Peter})
   {:ok, #PID<0.214.0>}
   ```
    
   Insert "Griffin" on r-tree named as Peter
   ```elixir
   iex> Drtree.insert({"Griffin",[{4,5},{6,7}]},Peter)
   {:ok,
   %{
    43143342109176739 => {["Griffin"], nil, [{4, 5}, {6, 7}]},
    :root => 43143342109176739,
    :ticket => [19125803434255161 | 82545666616502197],
    "Griffin" => {:leaf, 43143342109176739, [{4, 5}, {6, 7}]}
   }}
   ```

   Insert "Parker" on r-tree named as Peter
   ```elixir
   iex> Drtree.insert({"Parker",[{10,11},{16,17}]},Peter)
   {:ok,
   %{
    43143342109176739 => {["Parker", "Griffin"], nil, [{4, 11}, {6, 17}]},
    :root => 43143342109176739,
    :ticket => [19125803434255161 | 82545666616502197],
    "Griffin" => {:leaf, 43143342109176739, [{4, 5}, {6, 7}]},
    "Parker" => {:leaf, 43143342109176739, [{10, 11}, {16, 17}]}
   }}
   ```

   Query which leafs at Peter r-tree overlap with box `[{0,7},{4,8}]`
   ```elixir
   iex> Drtree.query([{0,7},{4,8}],Peter)
   {:ok, ["Griffin"]}
   ```
    
   Updates "Griffin" bounding box
   ```elixir
   iex> Drtree.update("Griffin",[{-6,-5},{11,12}],Peter)
   {:ok,
   %{
    43143342109176739 => {["Parker", "Griffin"], nil, [{-6, 11}, {6, 17}]},
    :root => 43143342109176739,
    :ticket => [19125803434255161 | 82545666616502197],
    "Griffin" => {:leaf, 43143342109176739, [{-6, -5}, {11, 12}]},
    "Parker" => {:leaf, 43143342109176739, [{10, 11}, {16, 17}]}
   }}
   ```

   Repeat again the last query
   ```elixir
   iex> Drtree.query([{0,7},{4,8}],Peter)
   {:ok, []} # Peter "Griffin" left the query bounding box
   ```
    
   Let's punish them
   ```elixir
   iex> Drtree.delete(["Griffin","Parker"],Peter)
   {:ok,
   %{
    43143342109176739 => {[], nil, [{0, 0}, {0, 0}]},
    :root => 43143342109176739,
    :ticket => [19125803434255161 | 82545666616502197]
   }}
   ```

  ## Easy concepts:

   Bounding box format.

   `[{x_min,x_max},{y_min,y_max}]`
```elixir
              Example:                               & & & & & y_max & & & & &
                A unit at pos x: 10, y: -12 ,        &                       &
                with x_size: 1 and y_size: 2         &                       &
                would be represented with            &          pos          &
                the following bounding box         x_min       (x,y)       x_max
                [{9.5,10.5},{-13,-11}]               &                       &
                                                     &                       &
                                                     &                       &
                                                     & & & & & y_min & & & & &
```

## Benchmarking

```elixir
Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-5257U CPU @ 2.70GHz
Number of Available Cores: 4
Available memory: 8 GB
Elixir 1.9.0
Erlang 22.0.7
```

### Delete
```elixir
Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 0 ns
parallel: 1
inputs: delete all leafs of tree [1000]
Estimated total run time: 28 s

##### With input delete all leafs of tree [1000] #####
Name                       ips        average  deviation         median         99th %
map bulk                175.20        5.71 ms     ±9.18%        5.60 ms        9.47 ms
merklemap bulk           80.27       12.46 ms    ±21.27%       11.74 ms       25.37 ms
map 1 by 1                4.68      213.68 ms     ±3.12%      213.24 ms      227.16 ms
merklemap 1 by 1          1.55      643.75 ms    ±14.80%      616.84 ms      878.20 ms

Comparison: 
map bulk                175.20
merklemap bulk           80.27 - 2.18x slower +6.75 ms
map 1 by 1                4.68 - 37.44x slower +207.97 ms
merklemap 1 by 1          1.55 - 112.79x slower +638.04 ms
```

### Update
```elixir
Benchmark suite executing with the following configuration:
warmup: 2 s
time: 10 s
memory time: 0 ns
parallel: 1
inputs: all leafs of tree [1000], all leafs of tree [100000]
Estimated total run time: 48 s

##### With input all leafs of tree [1000] #####
Name                ips        average  deviation         median         99th %
map              133.88        7.47 ms    ±22.82%        6.92 ms       14.83 ms
merklemap         65.74       15.21 ms    ±21.93%       14.18 ms       26.42 ms

Comparison: 
map              133.88
merklemap         65.74 - 2.04x slower +7.74 ms

##### With input all leafs of tree [100000] #####
Name                ips        average  deviation         median         99th %
map                0.68         1.46 s    ±15.84%         1.47 s         1.82 s
merklemap          0.33         3.01 s     ±8.23%         3.09 s         3.21 s

Comparison: 
map                0.68
merklemap          0.33 - 2.06x slower +1.55 s
```

### Query
```elixir
Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 0 ns
parallel: 1
inputs: 100x100 box query, 10x10 box query, 1x1 box query, world box query
Estimated total run time: 56 s

##### With input 100x100 box query #####
Name                ips        average  deviation         median         99th %
merklemap        299.97        3.33 ms    ±28.87%        3.03 ms        6.92 ms
map              268.51        3.72 ms    ±36.46%        3.35 ms        8.57 ms

Comparison: 
merklemap        299.97
map              268.51 - 1.12x slower +0.39 ms

##### With input 10x10 box query #####
Name                ips        average  deviation         median         99th %
map              1.50 K      667.16 μs    ±37.04%         594 μs     1557.56 μs
merklemap        1.01 K      992.92 μs    ±48.86%         883 μs     2418.52 μs

Comparison: 
map              1.50 K
merklemap        1.01 K - 1.49x slower +325.76 μs

##### With input 1x1 box query #####
Name                ips        average  deviation         median         99th %
map              2.01 K      498.54 μs    ±39.28%         430 μs        1257 μs
merklemap        1.51 K      660.89 μs    ±45.08%         603 μs     1551.25 μs

Comparison: 
map              2.01 K
merklemap        1.51 K - 1.33x slower +162.34 μs

##### With input world box query #####
Name                ips        average  deviation         median         99th %
map              156.18        6.40 ms    ±18.51%        5.99 ms       10.70 ms
merklemap        152.11        6.57 ms    ±26.12%        5.92 ms       13.93 ms

Comparison: 
map              156.18
merklemap        152.11 - 1.03x slower +0.171 ms

```

### Insert
```elixir
Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 0 ns
parallel: 1
inputs: 1000 leafs
Estimated total run time: 28 s

##### With input 1000 leafs #####
Name                       ips        average  deviation         median         99th %
map bulk                305.53        3.27 ms    ±39.39%        2.79 ms        7.96 ms
merklemap bulk          190.61        5.25 ms    ±62.06%        4.37 ms       17.65 ms
map 1 by 1               66.73       14.99 ms     ±4.63%       14.78 ms       19.11 ms
merklemap 1 by 1         23.00       43.48 ms    ±23.79%       39.24 ms       81.16 ms

Comparison: 
map bulk                305.53
merklemap bulk          190.61 - 1.60x slower +1.97 ms
map 1 by 1               66.73 - 4.58x slower +11.71 ms
merklemap 1 by 1         23.00 - 13.28x slower +40.21 ms

```


## Installation

The package can be installed
by adding `dynamic_rtree` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dynamic_rtree, "~> 0.2.0"}
  ]
end
```
## Usage

Everything is well defined and pretty at [documentation](https://hexdocs.pm/dynamic_rtree/0.2.0/).

You can also find the hex package [here](https://hex.pm/packages/dynamic_rtree/0.2.0).
