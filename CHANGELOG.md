# Changelog

## v0.2.14

* Bug fixes
  * Fix warnings when building with Elixir 1.11.

## v0.2.13

* Bug fixes
  * Improve error message when `:inets` isn't available so that it says how to
    add it to your `mix.exs`.

## v0.2.12

* Bug fixes
  * If help has been stripped, then don't tell the user that it's available.

* New features
  * Add `multicast_addresses` command for listing multicast addresses being
    listened to on each network interface. This is helpful if you're debugging
    lost multicast subscriptions or just seeing what applications are listening
    on.

## v0.2.11

* New features
  * Add `date` command for quickly checking the current date and time in UTC

## v0.2.10

* New features
  * Validate firmware using nerves_runtime v0.10.0's Nerves.Runtime.KV.put/2
    function if available

## v0.2.9

* New features
  * Add simple HTTP request shortcuts: `weather`, `qr_encode`, and `pastebin`

## v0.2.8

* New features
  * Add `ping` to ping a remote IP address repeatedly and add some
    support for setting the interface to use.

## v0.2.7

* New features
  * Add `lsmod` for returning loaded kernel modules on Nerves

## v0.2.6

* New features
  * Add `uname` for getting running firmware information on Nerves

## v0.2.5

* New features
  * Add `lsof`

## v0.2.4

* Bug fixes
  * Fix warning due to missing Nerves.Runtime

## v0.2.3

* Bug fixes
  * Fix `cmd/1` to capture and print stderr as well. This fixes an issue where
    stderr prints would go somewhere else and you couldn't see them. This
    affected IEx sessions running over ssh.

## v0.2.2

* Bug fixes
  * Fix ifconfig crash on sit interfaces
  * Improve printout of unnamed pids with top

* New features
  * Add `uptime` helper

## v0.2.1

* New features
  * Add `exit` for exiting an IEx session

## v0.2.0

* New features
  * `top` displays deltas by default

* Bug fixes
  * Fixed inclusion of Nerves utilities on Nerves

## v0.1.0

Initial release
