defmodule OT.Server.Mixfile do
  use Mix.Project

  @version "0.2.0"
  @github_url "https://github.com/jclem/ot_server"

  def project do
    [
      app: :ot_server,
      version: @version,
      description: description(),
      package: package(),
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),

      # Docs
      name: "OT.Server",
      homepage_url: @github_url,
      source_url: @github_url,
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {OT.Server.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ot_ex, "~> 0.1"},
      {:poolboy, "~> 1.5"},
      {:ex_doc, "~> 0.16", only: [:dev]}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end

  defp description do
    """
    OT.Server provides a generic server for submitting operations in an
    operational transformation system.
    """
  end

  defp package do
    [maintainers: ["Jonathan Clem <jonathan@jclem.net>"],
     licenses: ["ISC"],
     links: %{"GitHub" => @github_url}]
  end

  defp docs do
    [source_ref: "v#{@version}",
     main: "README.md",
     extras: ["README.md": [filename: "README.md", title: "Readme"],
              "LICENSE.md": [filename: "LICENSE.md", title: "License"]]]
  end
end
