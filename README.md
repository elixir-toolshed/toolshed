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
* `tree` - list directory contents as a tree
* `save_term`/`load_term` - save and load Elixir terms to files
* `tping` - check if a remote host is up (like ping, but uses TCP)
* `ifconfig` - list network interfaces
* `lsusb` - list USB devices

To try it out, add this project to your deps:

```elixir
def deps do
  [
    {:toolshed, "~> 0.1"}
  ]
end
```

Rebuild and run in whatever way you prefer. At the IEx prompt, run:

```elixir
iex> use Toolshed
Toolshed imported. Run h(Toolshed) for more info
:ok
iex> cmd("echo hello world")
hello world
0
iex> tping("google.com")
Host google.com (172.217.15.110) is up
```

When you get tired of typing `use Toolshed`, add it to your
[`.iex.exs`](https://hexdocs.pm/iex/IEx.html#module-the-iex-exs-file).

## FAQ

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


