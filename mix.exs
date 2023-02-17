defmodule Toolshed.MixProject do
  use Mix.Project

  @version "0.3.1"
  @source_url "https://github.com/elixir-toolshed/toolshed"

  def project do
    [
      app: :toolshed,
      version: @version,
      elixir: "~> 1.10",
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
        "hex.build": :docs,
        credo: :test
      }
    ]
  end

  def application do
    [
      env: [speed_test_url: "http://dl.nerves-project.org/speed_test/10MB.bin"],
      extra_applications: [:iex, :logger]
    ]
  end

  defp deps do
    [
      {:nerves_runtime, "~> 0.8", optional: true, only: [:dev, :test, :prod, :docs]},
      {:credo, "~> 1.2", only: :test, runtime: false},
      {:ex_doc, "~> 0.19", only: :docs, runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "Use Toolshed for more IEx helpers"
  end

  defp package do
    [
      files: [
        "lib",
        "lib_src",
        "mix.exs",
        "README.md",
        "LICENSE",
        "CHANGELOG.md"
      ],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp dialyzer() do
    [
      flags: [:missing_return, :extra_return, :unmatched_returns, :error_handling, :underspecs],
      plt_add_apps: [:iex, :nerves_runtime, :inets]
    ]
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme"
      # Don't include source refs since lines numbers don't match up to files
      # source_ref: "v#{@version}",
      # source_url: @source_url
    ]
  end
end
