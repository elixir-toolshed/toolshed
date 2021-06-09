defmodule Toolshed.ICMPPingTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  # CI can't send ICMP packets.
  unless System.get_env("CI") == "true" do
    describe "icmp_ping" do
      test "can ping an IPv4 address" do
        assert capture_io(fn ->
                 Toolshed.icmp_ping("127.0.0.1")
               end) =~ "Response from 127.0.0.1 (127.0.0.1): time="
      end

      test "can ping an IPv6 address" do
        assert capture_io(fn ->
                 Toolshed.icmp_ping("::1")
               end) =~ "Response from ::1 (::1): time="
      end

      test "can ping by hostname" do
        assert capture_io(fn ->
                 Toolshed.icmp_ping("localhost")
               end) =~ "Response from localhost (127.0.0.1): time="
      end

      test "times out if host doesn't exist" do
        assert capture_io(fn ->
                 Toolshed.icmp_ping("0.0.0.1", timeout: 1)
               end) =~ "0.0.0.1 (0.0.0.1): :timeout"
      end

      test "prints an error if host can't be resolved" do
        assert capture_io(fn ->
                 Toolshed.icmp_ping("this.host.does.not.exist")
               end) =~ "Error resolving this.host.does.not.exist"
      end

      test "can ping via a specific interface" do
        assert capture_io(fn ->
                 Toolshed.icmp_ping("127.0.0.1", ifname: "lo")
               end) =~ "Response from 127.0.0.1 (127.0.0.1): time="
      end

      test "prints an error if an interface is specified but not present" do
        assert capture_io(fn ->
                 Toolshed.icmp_ping("127.0.0.1", ifname: "not-present")
               end) =~ "127.0.0.1 (127.0.0.1): :eaddrnotavail"
      end
    end
  end
end
