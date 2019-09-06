defmodule Toolshed.MixProject do
  use Mix.Project

  @version "0.2.10"
  @source_url "https://github.com/fhunleth/toolshed"

  def project do
    [
      app: :toolshed,
      version: @version,
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      docs: docs(),
      package: package(),
      description: description()
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:nerves_runtime, "~> 0.8", optional: true},
      {:ex_doc, "~> 0.19", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "A toolshed of IEx helpers"
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp dialyzer() do
    [
      flags: [:race_conditions, :unmatched_returns, :error_handling, :underspecs],
      plt_add_apps: [:iex, :nerves_runtime, :inets]
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
