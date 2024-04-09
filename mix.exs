defmodule Shifts.MixProject do
  use Mix.Project

  def project do
    [
      app: :shifts,
      version: "0.1.0",
      elixir: "~> 1.13",
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
      {:anthropix, "~> 0.2"},
      {:ex_mustache, "~> 0.2"},
      {:nimble_options, "~> 1.1"},
      {:ollama, "~> 0.5"},
    ]
  end
end
