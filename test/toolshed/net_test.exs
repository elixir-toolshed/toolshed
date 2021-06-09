defmodule Toolshed.NetTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Toolshed.Net

  describe "tping" do
    test "can ping an IPv4 address" do
      assert capture_io(fn ->
               Net.tping("127.0.0.1")
             end) =~ "Response from 127.0.0.1 (127.0.0.1): time="
    end

    # This guards against an issue with IPv6 being unavailable in CI,
    # but also means CI won't run this test.
    unless System.get_env("CI") == "true" do
      test "can ping an IPv6 address" do
        assert capture_io(fn ->
                 Net.tping("::1")
               end) =~ "Response from ::1 (::1): time="
      end
    end

    test "can ping by hostname" do
      assert capture_io(fn ->
               Net.tping("localhost")
             end) =~ "Response from localhost (127.0.0.1): time="
    end

    test "prints an error if host can't be resolved" do
      assert capture_io(fn ->
               Net.tping("this.host.does.not.exist")
             end) =~ "Error resolving this.host.does.not.exist"
    end
  end
end
