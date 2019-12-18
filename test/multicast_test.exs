defmodule MulticastTest do
  use ExUnit.Case

  test "parses proc files" do
    # This formatting changes tabs and spaces. Linux does use tabs when
    # formatting the igmp table.
    dev_mcast = """
    2    eth0            1     0     333300000001
    2    eth0            1     0     01005e000001
    2    eth0            1     0     3333ff6fb53c
    """

    igmp = """
    Idx	Device    : Count Querier	Group    Users Timer	Reporter
    1	lo        :     1      V3
            010000E0     1 0:00000000		0
    2	eth0      :     1      V3
            010000E0     1 0:00000000		0
    """

    igmp6 = """
    1    lo              ff020000000000000000000000000001     1 0000000C 0
    1    lo              ff010000000000000000000000000001     1 00000008 0
    2    eth0            ff0200000000000000000001ff6fb53c     1 00000004 0
    2    eth0            ff020000000000000000000000000001     1 0000000C 0
    2    eth0            ff010000000000000000000000000001     1 00000008 0
    """

    result = """
    1: lo
       inet 224.0.0.1
       inet6 ff02::1
       inet6 ff01::1
    2: eth0
       link 33:33:00:00:00:01
       link 01:00:5e:00:00:01
       link 33:33:ff:6f:b5:3c
       inet 224.0.0.1
       inet6 ff02::1:ff6f:b53c
       inet6 ff02::1
       inet6 ff01::1
    """

    assert Toolshed.Multicast.process_proc(dev_mcast, igmp, igmp6) == result
  end
end
