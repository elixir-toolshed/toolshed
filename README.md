# Toolshed

[![CircleCI](https://circleci.com/gh/elixir-toolshed/toolshed.svg?style=svg)](https://circleci.com/gh/elixir-toolshed/toolshed)
[![Hex version](https://img.shields.io/hexpm/v/toolshed.svg "Hex version")](https://hex.pm/packages/toolshed)

Toolshed improves the Elixir shell experience by adding a number of IEx helpers.
This helps when a normal Unix shell prompt isn't easily accessible like on
[Nerves](https://nerves-project.org). It doesn't require Nerves, though, and all
Nerves-specific commands aren't even compiled if you're not using it.

Here's a sample list of helpers:

* `cmd` - run a command and print out the output
* `ping` and `tcping` - check if a remote host is using ICMP or TCP
* `ifconfig` - list network interfaces
* `weather` - get the current weather from [wttr.in](https://wttr.in/)
* `speed_test` - run a simple speed test to guage network throughput
* `top` - get a list of the top processes and their OTP applications based on
  CPU and memory
* `tree` - list directory contents as a tree
* `lsusb` - list USB devices

To get a complete list:

```elixir
iex> h Toolshed
```

To try it out, add this project to your deps:

```elixir
def deps do
  [
    {:toolshed, "~> 0.2"}
  ]
end
```

Rebuild and run in whatever way you prefer. At the IEx prompt, run:

```elixir
iex> use Toolshed
Toolshed imported. Run h(Toolshed) for more info.
:ok

iex> cmd("echo hello world")
hello world
0

iex> ping "nerves-project.org"
Press enter to stop
Response from nerves-project.org (185.199.108.153): time=4.155ms
Response from nerves-project.org (185.199.108.153): time=10.385ms
Response from nerves-project.org (185.199.108.153): time=12.458ms

iex> top
OTP Application  Name or PID               Reds/Δ      Mbox/Δ     Total/Δ      Heap/Δ     Stack/Δ
nerves_runtime   Nerves.Runtime.Kernel.UE   72M/10M     157/-32    384K/-4642  192K/73K      86/52
system_registry  SystemRegistry.Global      41M/6134K     0/0      694K/192K   192K/0        35/-11
system_registry  SystemRegistry.Processor   61M/6075K     0/0       73K/-1215   73K/0        10/0
system_registry  SystemRegistry.Registrat 1623K/293K      1/1      211K/109K    73K/0        10/0
system_registry  SystemRegistry.Processor  790K/197K     59/3     1011K/4461   502K/0        38/0
undefined        #PID<0.1793.0>            221K/68K       0/0       21K/0      6772/0       504/0
system_registry  SystemRegistry.Processor  382K/58K       0/0       16K/-1227  4185/-1354    22/0
ssh              #PID<0.1786.0>            133K/52K       0/0      4184/1599   2586/1599     10/0
nerves_init_gadg #PID<0.1432.0>            213K/39K       0/0      192K/101K    73K/0        10/0
```

When you get tired of typing `use Toolshed`, add it to your
[`.iex.exs`](https://hexdocs.pm/iex/IEx.html#module-the-iex-exs-file).

## FAQ

### I have some IEx helpers. Would you consider adding them?

Based on using and maintaining Toolshed the past several years, here's what ends
up working best:

1. Wrappers for OTP functions that make them easier to remember or format their
   output nicer for interactive use
2. Simple implementations of shell commands that have strong muscle memory for
   Linux users
3. Shortcuts to Linux system features (e.g., things that read `/sys` or `/proc`)

This project is not a Busybox replacement project or an effort to replicate all
of the functionality in shell commands. Erlang/OTP contains an awful lot of
built-in functionality. It's not identical to that provided by shell commands,
but if there's an easy way to get at it in an IEx helper, that's what we'd like
to do.

### A lot of these look like Unix commands? Why not run a proper shell?

Yeah, I miss many Unix commands when I'm at the IEx prompt. Switching to a shell
is easy on my laptop, but on Nerves devices, it's a pain. Getting a shell prompt
on Nerves is possible, but it's limited due to Nerves not containing a full set
of commands and it having to be run through Erlang's job control.

### Why is everything compiled to `toolshed.beam`?

When using Toolshed, the helpers are all imported into the IEx shell context for
ease of use. It looks like they're all defined in the `Toolshed` module. In
fact, if you don't `import Toolshed` (or `use Toolshed`), you can still access
the helpers by calling `Toolshed.helper()`. The problem defining all of the
helpers in one module is that it makes `toolshed.ex` very hard to maintain.

We've experimented with many ways of maintaining the helpers, like using
`defdelegate` and importing all of the helpers into `toolshed.ex`. There were
several problems with these ways including function docs not being in the
expected place, code being duplicated, and manual steps. The most annoying issue
was that keeping helpers in lots of `.beam` files had an impact on load time on
Nerves devices. The load-time issue is being addressed in OTP 26 more
generally.

The end result is that we finally settled on merging all of the helpers at
compile-time. The downside to this is that line numbers are wrong in stack
traces. Given the history of this issue, this seemed like a good compromise.

### You can do so much more with some of these helpers

Definitely. There's so much that I'd like to explore, but time gets in the way.
I'm not sold on many decisions that I made, but something was better than
nothing. Please help me improve this or make your own IEx helpers library. I'm
quite happy to use it too or pull it in as a dependency.

### I want to use one of the functions in my program. Is the API stable?

This isn't a normal hex.pm library. Use it for the helpers. If you want
some code, copy and paste it or incorporate it into a library. I'd like the
flexibility to change the API to improve interactive use.

### It would be better if you changed the colors

This also isn't a question, and you've now made me regret naming the project
`toolshed`. Please file your grievances
[here](https://github.com/elixir-toolshed/toolshed/pull/5).
