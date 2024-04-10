defmodule Shifts.MixProject do
  use Mix.Project

  def project do
    [
      app: :shifts,
      name: "Shifts",
      description: "An Elixir framework for composing autonomous AI agent workflows, using a mixture of LLM backends.",
      source_url: "https://github.com/lebrunel/shifts",
      version: "0.0.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "Shifts"
      ],
      package: [
        name: "shifts",
        files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
        licenses: ["Apache-2.0"],
        links: %{
          "GitHub" => "https://github.com/lebrunel/shifts"
        }
      ]
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
      {:anthropix, "~> 0.2"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:ex_mustache, "~> 0.2"},
      {:jason, "~> 1.4"},
      {:nimble_options, "~> 1.1"},
      {:ollama, "~> 0.5"},
    ]
  end
end
