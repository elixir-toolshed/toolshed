defmodule Toolshed.MixProject do
  use Mix.Project

  @version "0.2.18"
  @source_url "https://github.com/fhunleth/toolshed"

  def project do
    [
      app: :toolshed,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      docs: docs(),
      package: package(),
      description: description(),
      xref: [exclude: [:httpc]],
      preferred_cli_env: %{
        docs: :docs,
        "hex.publish": :docs,
        "hex.build": :docs
      }
    ]
  end

  def application do
    [extra_applications: [:iex]]
  end

  defp deps do
    [
      {:nerves_runtime, "~> 0.8", optional: true},
      {:ex_doc, "~> 0.19", only: :docs, runtime: false},
      {:dialyxir, "~> 1.0.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "Use Toolshed for path completion and more helpers for IEx"
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
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
