# Disable ANSI escape codes in output
Application.put_env(:elixir, :ansi_enabled, false)

ExUnit.start()
