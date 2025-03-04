# SPDX-FileCopyrightText: 2021 Alex McLain
# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Toolshed.ICMPPingTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  @tag :icmp
  test "can ping an IPv4 address" do
    assert capture_io(fn ->
             Toolshed.ping("127.0.0.1", count: 1)
           end) =~ "Response from 127.0.0.1 (127.0.0.1): icmp_seq="
  end

  @tag :icmp
  test "can ping by hostname" do
    assert capture_io(fn ->
             Toolshed.ping("localhost", count: 1)
           end) =~ "Response from localhost (127.0.0.1): icmp_seq="
  end

  @tag :icmp
  test "times out if host doesn't exist" do
    assert capture_io(fn ->
             Toolshed.ping("0.0.0.1", timeout: 1, count: 1)
           end) =~ "0.0.0.1 (0.0.0.1): :ehostunreach"
  end

  test "prints an error if host can't be resolved" do
    assert capture_io(fn ->
             Toolshed.ping("this.host.does.not.exist", count: 1)
           end) =~ "Error resolving this.host.does.not.exist"
  end

  @tag :icmp
  test "can ping via a specific interface" do
    lo = local_ifname()

    assert capture_io(fn ->
             Toolshed.ping("127.0.0.1", ifname: lo, count: 1)
           end) =~ "Response from 127.0.0.1 (127.0.0.1): icmp_seq="
  end

  @tag :icmp
  test "prints an error if an interface is specified but not present" do
    assert capture_io(fn ->
             Toolshed.ping("127.0.0.1", ifname: "not-present", count: 1)
           end) =~ "127.0.0.1 (127.0.0.1): :eaddrnotavail"
  end

  defp local_ifname() do
    {:ok, ifaddrs} = :inet.getifaddrs()

    Enum.find_value(ifaddrs, "lo", fn {ifname_c, _} ->
      ifname = List.to_string(ifname_c)

      if String.starts_with?(ifname, "lo") do
        ifname
      end
    end)
  end
end
