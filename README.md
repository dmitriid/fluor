# DEPRECATED IN FAVOR OF [dmitriid/tetrad](https://github.com/dmitriid/tetrad)

# Fluor

The only integration in the world that properly integrates Slack and Jabber.

Connect to serveral group chats in Jabber. Connect to several chat channels in Slack. Watch how messages get carried between the two

Hacky, put together in half-an-hour-ish mess of code that works.

## Installation

1. Clone
2. `mix deps.get`
3. Config:
```elixir
# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :fluor,
  slack_token: "you-slack-api-token",
  jabber: [user: "your-jid",
           password: "your-password",
           rooms: ["list", "of", "rooms", "to", "join"]
          ],
  mapping: %{"some-slack-channel" => "jabber-room",
             "jabber-room" => "some-slack-channel"}


config :logger, level: :info

```
4. `iex -S mix`
5. `Fluor.init`
