defmodule Toolshed.TpingTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Toolshed.Tping

  test "can ping an IPv4 address" do
    assert capture_io(fn ->
             tping("127.0.0.1")
           end) =~ "Response from 127.0.0.1 (127.0.0.1:80): time="
  end

  # This guards against an issue with IPv6 being unavailable in CI,
  # but also means CI won't run this test.
  @tag :has_ipv6
  test "can ping an IPv6 address" do
    assert capture_io(fn ->
             tping("::1")
           end) =~ "Response from ::1 ([::1]:80): time="
  end

  test "can ping by hostname" do
    assert capture_io(fn ->
             tping("localhost")
           end) =~ "Response from localhost (127.0.0.1:80): time="
  end

  test "prints an error if host can't be resolved" do
    assert capture_io(fn ->
             tping("this.host.does.not.exist")
           end) =~ "Error resolving this.host.does.not.exist"
  end
end
