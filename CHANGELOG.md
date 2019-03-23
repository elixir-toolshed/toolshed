# Changelog

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
