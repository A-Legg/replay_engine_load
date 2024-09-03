defmodule ReplayEngineLoad.MixProject do
  use Mix.Project

  def project do
    [
      app: :replay_engine_load,
      version: "0.1.0",
      elixir: "~> 1.17-rc",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ReplayEngineLoad.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:websockex, "~> 0.4.3"},
      {:jason, "~> 1.2"},
      {:uuid, "~> 1.1"},
      {:req, "~> 0.3.0"}
    ]
  end
end
