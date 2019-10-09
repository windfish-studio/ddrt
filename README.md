# DynamicRtree
[![CircleCI](https://circleci.com/gh/windfish-studio/dynamic-rtree/tree/master.svg?style=svg)](https://circleci.com/gh/windfish-studio/dynamic-rtree/tree/master)

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

  ## Important points:
  ```elixir
    If you want to use the %{database: true} option, you have to get dev dependencies.

    Every id inserted must be uniq, Drtree won't crush the duplicated id.

    Every bounding box should look like this: [{xm,xM},{ym,yM}]
    - xm: minimum x value
    - xM: maximum x value
    - ym: minimum y value
    - yM: maximum y value
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

Everything is well defined and pretty at [documentation](https://hexdocs.pm/elixir_rtree).


