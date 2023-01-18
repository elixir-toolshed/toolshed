defmodule ToolshedTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  @core_helpers [
    cat: 1,
    cmd: 1,
    date: 0,
    grep: 2,
    hex: 1,
    history: 0,
    history: 1,
    hostname: 0,
    httpget: 1,
    httpget: 2,
    ifconfig: 0,
    inspect_bits: 1,
    load_term!: 1,
    log_attach: 0,
    log_attach: 1,
    log_detach: 0,
    lsof: 0,
    lsusb: 0,
    multicast_addresses: 0,
    nslookup: 1,
    ping: 1,
    ping: 2,
    qr_encode: 1,
    save_term!: 2,
    save_value: 2,
    save_value: 3,
    top: 0,
    top: 1,
    tping: 1,
    tping: 2,
    tree: 0,
    tree: 1,
    uptime: 0,
    weather: 0
  ]

  @nerves_runtime_helpers [
    dmesg: 0,
    exit: 0,
    fw_validate: 0,
    lsmod: 0,
    poweroff: 0,
    reboot: 0,
    reboot!: 0,
    uname: 0
  ]

  test "public functions" do
    import Toolshed

    # Make the unused import warning go away
    hex(40)

    helpers = __ENV__.functions |> Keyword.get(Toolshed)

    expected = Enum.sort(@core_helpers ++ @nerves_runtime_helpers)

    # Check that the only functions exported are the helpers
    assert expected == helpers
  end

  test "original tool modules don't exist" do
    # Functions in the original tool modules should have been combined
    # into the big toolshed.beam file. They shouldn't exist. Run spot
    # checks just in case.
    assert {:error, :nofile} = Code.ensure_compiled(Toolshed.Core.Cat)
    assert {:error, :nofile} = Code.ensure_compiled(Toolshed.Core.Date)
    assert {:error, :nofile} = Code.ensure_compiled(Toolshed.Core.Grep)
    assert {:error, :nofile} = Code.ensure_compiled(Toolshed.NervesRuntime.Dmesg)
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
