defmodule Kindling.MixProject do
  use Mix.Project

  def project do
    [
      app: :kindling,
      version: version(),
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Resource generators and API clients for HL7 FHIR.",

      # Docs
      source_url: "https://code.mythicinsight.com/mythic-insight/kindling",
      docs: [
        main: "Kindling"
      ],

      # Hex
      package: %{
        licenses: ["MIT"],
        links: %{
          "source" => "https://code.mythicinsight.com/mythic-insight/kindling"
        }
      }
    ]
  end

  def version do
    [_, version] =
      "README.md"
      |> File.read!()
      |> then(&Regex.run(~r/{:kindling, "~> ([^"]+)"}/, &1))

    version
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
      {:credo, "~> 1.7", only: [:dev]},
      {:ecto, "~> 3.11"},
      {:ex_doc, "~> 0.31.2", only: [:dev]},
      {:jason, "~> 1.4"},
      {:recase, "~> 0.7.0"},
      {:req, "~> 0.5"},
      {:saxy, "~> 1.5.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
