defmodule Toolshed.Ping do
  @moduledoc """
  This module provides the `ping` command
  """

  @doc """
  Ping an IP address using TCP

  This tries to connect to the remote host using TCP instead of sending an ICMP
  echo request like normal ping. This made it possible to write in pure Elixir.

  NOTE: Specifying an `:ifname` only sets the source IP address for the TCP
  connection. This is only a hint to use the specified interface and not a
  guarantee. For example, if you have two interfaces on the same LAN, the OS
  routing tables may send traffic out one interface in preference to the one
  that you want. On Linux, you can enable policy-based routing and add source
  routes to guarantee that packets go out the desired interface.

  Options:

  * `:ifname` - Specify a network interface to use. (e.g., "eth0")
  * `:port` - Which TCP port to try (defaults to 80)

  ## Examples

      iex> ping "nerves-project.org"
      Press enter to stop
      Response from nerves-project.org (185.199.108.153:80): time=4.155ms
      Response from nerves-project.org (185.199.108.153:80): time=10.385ms
      Response from nerves-project.org (185.199.108.153:80): time=12.458ms

      iex> ping "google.com", ifname: "wlp5s0"
      Press enter to stop
      Response from google.com (172.217.7.206:80): time=88.602ms
  """
  @spec ping(String.t(), keyword()) :: :"do not show this result in output"
  def ping(address, options \\ []) do
    IO.puts("Press enter to stop")

    pid = spawn(fn -> repeat_ping(address, options) end)
    _ = IO.gets("")
    Process.exit(pid, :kill)

    IEx.dont_display_result()
  end

  defp repeat_ping(address, options) do
    Toolshed.tping(address, options)
    Process.sleep(1000)
    repeat_ping(address, options)
  end
end
