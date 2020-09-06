defmodule Espy.MixProject do
  use Mix.Project

  def project do
    [
      app: :espy,
      version: "0.1.0",
      elixir: "~> 1.10",
      build_path: "./_build",
      config_path: "./config/config.exs",
      deps_path: "./deps",
      lockfile: "./mix.lock",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Espy.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:socket, "~> 0.3"},
      {:ex_crypto, "~> 0.10"},
      {:crypto_rand, "~>1.0"},
      {:curve25519, "~> 1.0"},
      {:bitwise_binary, "~> 0.3"},
      {:math, "~> 0.5"},
      {:ord_map, "~> 0.1"},
      {:jason, "~> 1.2"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.22", only: [:dev], runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
