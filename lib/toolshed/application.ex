defmodule Toolshed.Application do
  def config() do
    ["use Mix.Config\n\n" | format_all_applications()] |> IO.puts()
  end

  defp format_all_applications() do
    Application.loaded_applications()
    |> Enum.map(&format_application/1)
  end

  defp format_application({app, _name, _version}) do
    case Application.get_all_env(app) do
      [] ->
        []

      env ->
        ["config ", inspect(app), ",\n", format_config(env), "\n"]
    end
  end

  defp format_config(env) do
    env
    |> Enum.map(fn {k, v} -> ["   ", to_string(k), ": ", inspect(v), "\n"] end)
  end
end
