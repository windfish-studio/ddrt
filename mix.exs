defmodule DynamicRtree.MixProject do
  use Mix.Project

  def project do
    [
      app: :dynamic_rtree,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      { :uuid , "~> 1.1"},
      { :dlex , git: "https://github.com/windfish-studio/dlex", branch: "master"},
      { :jason , "~> 1.0"},
      { :benchee, "~> 1.0", only: :dev},
      { :earmark, "~> 1.2", only: :dev},
      { :ex_doc, "~> 0.19", only: :dev},
      {:dialyxir, "~> 0.4", only: :dev}

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
