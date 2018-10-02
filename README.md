# MyHelpers

This package adds a number of IEx helpers. This is an experiment.

To try it out, add this project to your deps:

```elixir
def deps do
  [
    {:my_helpers, github: "fhunleth/my_helpers"}
  ]
end
```

Rebuild and run in whatever way you prefer. At the IEx prompt, run:

```elixir
iex> use MyHelpers
```

You'll have a number of functions added available to you. Many are half-baked.
Try out some in this list or run `h function` to find out more.

* `cat`
* `grep`
* `top`
* `tree`
* `cmd`
* `reboot` (Nerves-only)
* `dmesg`  (Nerves-only)

Please feel free to add more and send PRs back or let me know if you'd like to
collaborate.

## Archive installation

(This doesn't work, but I'd like to have some way of always loading the helpers
so I'm keeping it for now.)

If you'd like the helpers to be available every time you use IEx, you can
install `MyHelpers` as an archive:

```sh
mix archive.install hex my_helpers
```

Then in your `.iex.exs`, add this:

```elixir
Path.join([Mix.Utils.mix_home(), "archives", "my_helpers-0.1.0", "my_helpers-0.1.0", "ebin"])
|> Code.append_path()

use MyHelpers
```


