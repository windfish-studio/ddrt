[![CircleCI](https://circleci.com/gh/windfish-studio/dynamic-rtree/tree/master.svg?style=svg)](https://circleci.com/gh/windfish-studio/dynamic-rtree/tree/master)
![LICENSE](https://img.shields.io/hexpm/l/dynamic_rtree)
![VERSION](https://img.shields.io/hexpm/v/dynamic_rtree)
# DynamicRtree

 This is the API module of the elixir r-tree implementation where you can do the basic actions.

  ## Actions provided:
  ```elixir
      - insert/2
      - query/2
      - query/3
      - delete/2
      - update_leaf/3
      - execute/1
   ```

## Installation

The package can be installed
by adding `dynamic_rtree` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dynamic_rtree, "~> 0.1.0"}
  ]
end
```
## Usage

Everything is well defined and pretty at [documentation](https://hexdocs.pm/dynamic_rtree/0.1.0/Drtree.html).

You can also find the hex package [here](https://hex.pm/packages/dynamic_rtree/0.1.0).

## Benchmarking

### Delete
```elixir
Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-5257U CPU @ 2.70GHz
Number of Available Cores: 4
Available memory: 8 GB
Elixir 1.9.0
Erlang 22.0.7

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 0 ns
parallel: 1
inputs: tree [1000], tree [10000], tree [100000]
Estimated total run time: 21 s

Benchmarking delete [random leaf] with input tree [1000]...
Benchmarking delete [random leaf] with input tree [10000]...
Benchmarking delete [random leaf] with input tree [100000]...

##### With input tree [1000] #####
Name                           ips        average  deviation         median         99th %
delete [random leaf]      102.55 K        9.75 μs    ±65.82%           9 μs       60.94 μs

##### With input tree [10000] #####
Name                           ips        average  deviation         median         99th %
delete [random leaf]       33.06 K       30.25 μs     ±3.91%          30 μs          32 μs

##### With input tree [100000] #####
Name                           ips        average  deviation         median         99th %
delete [random leaf]          40 K          25 μs    ±22.63%          25 μs          29 μs
```

### Update
```elixir
Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-5257U CPU @ 2.70GHz
Number of Available Cores: 4
Available memory: 8 GB
Elixir 1.9.0
Erlang 22.0.7

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 10 s
memory time: 0 ns
parallel: 1
inputs: tree [1000], tree [10000], tree [100000]
Estimated total run time: 36 s

Benchmarking continuous update with input tree [1000]...
Benchmarking continuous update with input tree [10000]...
Benchmarking continuous update with input tree [100000]...

##### With input tree [1000] #####
Name                        ips        average  deviation         median         99th %
continuous update        115.17        8.68 ms    ±40.88%        7.45 ms       25.37 ms

##### With input tree [10000] #####
Name                        ips        average  deviation         median         99th %
continuous update         12.70       78.74 ms     ±7.45%       76.99 ms       91.57 ms

##### With input tree [100000] #####
Name                        ips        average  deviation         median         99th %
continuous update          0.93         1.08 s     ±7.94%         1.05 s         1.24 s
```
### Query
```elixir
Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-5257U CPU @ 2.70GHz
Number of Available Cores: 4
Available memory: 8 GB
Elixir 1.9.0
Erlang 22.0.7

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 0 ns
parallel: 1
inputs: 100x100 box query, 10x10 box query, 1x1 box query, world box query
Estimated total run time: 1.40 min

Benchmarking tree [1000 leafs] with input 100x100 box query...
Benchmarking tree [1000 leafs] with input 10x10 box query...
Benchmarking tree [1000 leafs] with input 1x1 box query...
Benchmarking tree [1000 leafs] with input world box query...
Benchmarking tree [10000 leafs] with input 100x100 box query...
Benchmarking tree [10000 leafs] with input 10x10 box query...
Benchmarking tree [10000 leafs] with input 1x1 box query...
Benchmarking tree [10000 leafs] with input world box query...
Benchmarking tree [100000 leafs] with input 100x100 box query...
Benchmarking tree [100000 leafs] with input 10x10 box query...
Benchmarking tree [100000 leafs] with input 1x1 box query...
Benchmarking tree [100000 leafs] with input world box query...

##### With input 100x100 box query #####
Name                          ips        average  deviation         median         99th %
tree [1000 leafs]         2786.01        0.36 ms    ±42.21%        0.31 ms        0.98 ms
tree [10000 leafs]         263.88        3.79 ms    ±71.01%        3.12 ms       14.39 ms
tree [100000 leafs]         27.65       36.16 ms    ±31.55%       31.64 ms      100.82 ms

Comparison: 
tree [1000 leafs]         2786.01
tree [10000 leafs]         263.88 - 10.56x slower +3.43 ms
tree [100000 leafs]         27.65 - 100.75x slower +35.80 ms

##### With input 10x10 box query #####
Name                          ips        average  deviation         median         99th %
tree [1000 leafs]          7.56 K      132.32 μs   ±268.69%         107 μs      367.48 μs
tree [10000 leafs]         1.52 K      658.95 μs   ±175.00%         500 μs     2302.66 μs
tree [100000 leafs]        0.27 K     3728.35 μs    ±24.95%        3482 μs     6102.92 μs

Comparison: 
tree [1000 leafs]          7.56 K
tree [10000 leafs]         1.52 K - 4.98x slower +526.63 μs
tree [100000 leafs]        0.27 K - 28.18x slower +3596.03 μs

##### With input 1x1 box query #####
Name                          ips        average  deviation         median         99th %
tree [1000 leafs]         11.80 K       84.77 μs   ±208.07%          67 μs         311 μs
tree [10000 leafs]         2.49 K      401.61 μs   ±138.07%         289 μs     1539.88 μs
tree [100000 leafs]        0.81 K     1237.44 μs    ±66.31%        1051 μs     3267.45 μs

Comparison: 
tree [1000 leafs]         11.80 K
tree [10000 leafs]         2.49 K - 4.74x slower +316.84 μs
tree [100000 leafs]        0.81 K - 14.60x slower +1152.67 μs

##### With input world box query #####
Name                          ips        average  deviation         median         99th %
tree [1000 leafs]         3048.78        0.33 ms    ±41.19%        0.29 ms        0.81 ms
tree [10000 leafs]         323.73        3.09 ms    ±14.12%        2.94 ms        4.90 ms
tree [100000 leafs]         15.93       62.79 ms     ±7.50%       62.05 ms       93.63 ms

Comparison: 
tree [1000 leafs]         3048.78
tree [10000 leafs]         323.73 - 9.42x slower +2.76 ms
tree [100000 leafs]         15.93 - 191.43x slower +62.46 ms

```

### Insert
```elixir
Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-5257U CPU @ 2.70GHz
Number of Available Cores: 4
Available memory: 8 GB
Elixir 1.9.0
Erlang 22.0.7

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 0 ns
parallel: 1
inputs: 1000 leafs, 10000 leafs, 100000 leafs
Estimated total run time: 42 s

Benchmarking tree [100000] with input 1000 leafs...
Benchmarking tree [100000] with input 10000 leafs...
Benchmarking tree [100000] with input 100000 leafs...
Benchmarking tree [empty] with input 1000 leafs...
Benchmarking tree [empty] with input 10000 leafs...
Benchmarking tree [empty] with input 100000 leafs...

##### With input 1000 leafs #####
Name                    ips        average  deviation         median         99th %
tree [empty]          33.16       30.16 ms    ±57.33%       27.06 ms      175.02 ms
tree [100000]          8.15      122.63 ms     ±0.00%      122.63 ms      122.63 ms

Comparison: 
tree [empty]          33.16
tree [100000]          8.15 - 4.07x slower +92.47 ms

##### With input 10000 leafs #####
Name                    ips        average  deviation         median         99th %
tree [empty]           2.44      410.03 ms    ±28.11%      363.34 ms      737.25 ms
tree [100000]          2.27      441.37 ms     ±0.00%      441.37 ms      441.37 ms

Comparison: 
tree [empty]           2.44
tree [100000]          2.27 - 1.08x slower +31.34 ms

##### With input 100000 leafs #####
Name                    ips        average  deviation         median         99th %
tree [empty]           0.22         4.56 s     ±7.30%         4.56 s         4.80 s
tree [100000]         0.158         6.35 s     ±0.00%         6.35 s         6.35 s

Comparison: 
tree [empty]           0.22
tree [100000]         0.158 - 1.39x slower +1.78 s
```
