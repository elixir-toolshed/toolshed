defmodule Toolshed.NervesRuntime.Lsmod do
  @doc """
  Print out the loaded kernel modules

  Aside from printing out whether the kernel has been tainted, the
  Linux utility of the same name just dump the contents of "/proc/modules"
  like this one.

  Some kernel modules may be built-in to the kernel image. To see
  those, run `cat "/lib/modules/x.y.z/modules.builtin"` where `x.y.z` is
  the kernel's version number.
  """
  @spec lsmod() :: :"do not show this result in output"
  def lsmod() do
    Toolshed.cat("/proc/modules")
  end
end
