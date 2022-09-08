defmodule ToolshedTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  @toolshed_commands [
    cat: 1,
    cmd: 1,
    date: 0,
    grep: 2,
    hex: 1,
    history: 1,
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
    top: 1,
    tping: 2,
    tree: 1,
    uptime: 0,
    weather: 0
  ]

  test "public functions" do
    actual = Toolshed.__info__(:functions)

    for f <- @toolshed_commands, do: assert(f in actual)
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
