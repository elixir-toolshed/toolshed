# SPDX-FileCopyrightText: 2018 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
# Disable ANSI escape codes in output
Application.put_env(:elixir, :ansi_enabled, false)

ExUnit.start()
