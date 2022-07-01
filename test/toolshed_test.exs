defmodule ToolshedTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  @generic_functions [
    cat: 1,
    cmd: 1,
    date: 0,
    exit: 0,
    grep: 2,
    hex: 1,
    history: 0,
    hostname: 0,
    httpget: 2,
    ifconfig: 0,
    load_term!: 1,
    log_attach: 1,
    log_detach: 0,
    lsof: 0,
    lsusb: 0,
    multicast_addresses: 0,
    nslookup: 1,
    ping: 2,
    qr_encode: 1,
    save_term!: 2,
    save_value: 3,
    top: 0,
    tping: 2,
    tree: 0,
    uptime: 0,
    weather: 0
  ]

  @nerves_specific_functions [
    dmesg: 0,
    fw_validate: 0,
    lsmod: 0,
    reboot: 0,
    reboot!: 0,
    uname: 0
  ]

  test "public functions" do
    expected = @generic_functions ++ @nerves_specific_functions
    actual = Toolshed.__info__(:functions)

    for f <- expected, do: assert(f in actual)
  end

  test "cmd/1 normal printable chars" do
    assert capture_io(fn ->
             Toolshed.cmd("printf \"hello, world\"")
           end) == "hello, world"
  end

  test "cmd/1 non printable chars" do
    assert capture_io(fn ->
             Toolshed.cmd("printf '\\x0'")
           end) == <<0>>
  end
end
