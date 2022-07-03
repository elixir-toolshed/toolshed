defmodule Toolshed.LogTest do
  use ExUnit.Case

  import ExUnit.CaptureIO
  import ExUnit.CaptureLog

  require Logger

  @default_options [format: "unittest[$level] $message\n", colors: [enabled: false]]

  defp capture_io_and_not_log(function) do
    capture_io(fn -> capture_log(function) end)
  end

  test "logging events while attached and detached" do
    output =
      capture_io_and_not_log(fn ->
        Toolshed.log_attach(@default_options)
        Logger.info("hello1")
        Toolshed.log_detach()
        Logger.error("shouldn't log")
      end)

    assert output == "unittest[info] hello1\n"
  end

  test "detaching returns an error when not attached" do
    assert {:error, :not_attached} = Toolshed.log_detach()
  end

  test "attaching twice returns an error" do
    assert {:ok, _pid} = Toolshed.log_attach()
    assert {:error, :detach_first} == Toolshed.log_attach()
    assert :ok == Toolshed.log_detach()
  end

  test "filtering by log level" do
    output =
      capture_io_and_not_log(fn ->
        {:ok, _pid} = Toolshed.log_attach(@default_options ++ [level: :error])
        Logger.error("hello1")
        Logger.info("shouldn't log")
      end)

    assert output == "unittest[error] hello1\n"
  end

  defp backend_count() do
    Logger.BackendSupervisor
    |> Supervisor.count_children()
    |> Map.get(:workers, 0)
  end

  test "detaches when group leader dies" do
    old_gl = Process.group_leader()
    {:ok, new_gl} = StringIO.open("")

    Process.group_leader(self(), new_gl)

    original_count = backend_count()

    # Attach -> this should cause there to be a new backend
    {:ok, _pid} = Toolshed.log_attach(@default_options)
    assert backend_count() == original_count + 1

    # Set the group leader back and exit the new one we made
    Process.group_leader(self(), old_gl)
    StringIO.close(new_gl)

    # Should be back to the original backend count
    Process.sleep(10)
    assert backend_count() == original_count
  end
end
