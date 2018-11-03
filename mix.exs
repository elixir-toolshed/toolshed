defmodule Toolshed.MixProject do
  use Mix.Project

  def project do
    [
      app: :toolshed,
      version: "0.2.2",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [extras: ["README.md"]],
      description: description(),
      package: package(),
      dialyzer: [plt_add_apps: [:iex]]
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev, :test], runtime: false},
      {:nerves_runtime, "~> 0.4", optional: true}
    ]
  end

  defp description do
    "A toolshed full of IEx helpers"
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/fhunleth/toolshed"}
    ]
  end
end
