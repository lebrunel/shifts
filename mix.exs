defmodule Shifts.MixProject do
  use Mix.Project

  def project do
    [
      app: :shifts,
      version: "0.1.0",
      elixir: "~> 1.16",
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
      {:anthropix, "~> 0.3", optional: true},
      {:ex_doc, "~> 0.32", only: :dev, runtime: false},
      {:nimble_options, "~> 1.1"},
      {:ollama, "~> 0.6", optional: true},
    ]
  end
end
