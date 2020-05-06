# Toolshed

[![CircleCI](https://circleci.com/gh/fhunleth/toolshed.svg?style=svg)](https://circleci.com/gh/fhunleth/toolshed)
[![Hex version](https://img.shields.io/hexpm/v/toolshed.svg "Hex version")](https://hex.pm/packages/toolshed)

This package adds a number of commands to the IEx prompt to make working at the
console more enjoyable. It's an experiment in aggregating code snippets from
projects into one place. Some utilities merely wrap Erlang functions that are
hard to remember and some actually do quite a bit of work. Please make my
helpers your helpers too and send some back.

Here's a sample of what you'll get:

* `cmd` - run a command and print out the output
* `top` - get a list of the top processes and their OTP applications based on
  CPU and memory
* `exit` - exit an IEx session (useful over ssh)
* `tree` - list directory contents as a tree
* `save_term`/`load_term` - save and load Elixir terms to files
* `ping` - check if a remote host is up (almost like ping, but uses TCP instead
  of ICMP to avoid needing additional permissions)
* `ifconfig` - list network interfaces
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

Yes! Absolutely. Please send a PR. At some point I may have to whittle down
what's in the library, but for now, I'm open to adding almost anything.

This includes:

1. Pretty much anything that helps debugging or inspecting a running system
2. Wrappers on OTP functions that are hard to remember or have output that's not
   ideal for interactive use.
3. Fun stuff - submit a text game if it's not too long if you'd like.

I'd really like to stay away from adding anything that's not Elixir to this
project. I.e., no port processes or NIFs. It would also be nice to keep Toolshed
low on dependencies. Of course, maybe I'm just not thinking of something. Don't
let that be a reason to not file an issue proposing the idea. If it doesn't seem
to fit well, maybe a simplified version does and we add a link to the full
featured one.

### A lot of these look like Unix commands? Why not run a proper shell?

Yeah, I miss many Unix commands when I'm at the IEx prompt. Switching to a shell
is easy on my laptop, but on Nerves devices, it's a pain. Getting a shell prompt
on Nerves is possible, but it's limited due to Nerves not containing a full set
of commands and it having to be run through Erlang's job control.

### Not having file name tab completion is painful.

That's not a question, but yes. If you have ideas on how to fix, please tell!

### You can do so much more with some of these helpers!!!

Definitely. There's so much that I'd like to explore, but time gets in the way.
I'm not sold on many decisions that I made, but something was better than
nothing. Please help me improve this or make your own IEx helpers library. I'm
quite happy to use it too or pull it in as a dependency.

### I want to use one of the functions in my program. Is the API stable?

This really isn't a normal hex.pm library. Use it for the helpers. If you want
some code, copy and paste it or incorporate it into a library. I'd like the
flexibility to change the API to improve interactive use.

### It would be better if you changed the colors.

This also isn't a question, and you've now made me regret naming the project
`toolshed`. Please file your grievances
[here](https://github.com/fhunleth/toolshed/pull/5).
