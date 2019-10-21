defmodule DynamicRtree.MixProject do
  use Mix.Project

  def project do
    [
      app: :dynamic_rtree,
      version: "0.2.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/windfish-studio/dynamic-rtree",
      description: description(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:uuid, "~> 1.1"},
      {:jason, "~> 1.0"},
      {:benchee, "~> 1.0", only: :dev},
      {:earmark, "~> 1.2", only: :dev},
      {:ex_doc, "~> 0.19", only: :dev},
      {:dialyxir, "~> 0.4", only: :dev},
      {:merkle_map, "~> 0.2.0"},
      {:libcluster, "~> 3.1.1"},
      {:delta_crdt, "~> 0.5.0"}
    ]
  end

  defp package() do
    [
      licenses: ["GPL 3.0"],
      links: %{"GitHub" => "https://github.com/windfish-studio/dynamic-rtree"}
    ]
  end

  def description do
    "Distributed Dynamic R-tree (DDRT) implementation for Elixir.

    It's mainly a R-tree.

    Why dynamic? Because it's optimized to do fast updates at the tree leafs spatial index.

    Why distributed? Well.. you can run the DDRT on different nodes and they will have the same r-tree data.
    "
  end
end
