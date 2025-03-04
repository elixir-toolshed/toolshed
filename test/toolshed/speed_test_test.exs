# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Toolshed.SpeedTestTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "default URL" do
    assert capture_io(fn ->
             Toolshed.speed_test(duration: 500)
           end) =~ "Download speed: "
  end

  test "passing a bad URL returns an nxdomain error" do
    assert capture_io(fn ->
             Toolshed.speed_test(
               url: "http://does_not_exist.nerves-project.org/file.bin",
               duration: 500
             )
           end) =~ "Can't connect to does_not_exist.nerves-project.org: :nxdomain"
  end

  test "passing a zero-length file still works" do
    # nerves-project.org only serves https, so this should be 0 bytes.
    assert capture_io(fn ->
             Toolshed.speed_test(
               url: "http://nerves-project.org/index.html",
               duration: 500
             )
           end) =~ "0 bytes received in 0.0 s\nDownload speed: 0 bps"
  end
end
