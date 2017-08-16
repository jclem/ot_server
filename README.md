# OT.Server

`OT.Server` is an application that manages the correct handling of submitted
operations in an operational transformation system. It ships with an adapter
for persisting data to ETS, but implementing new adapters is simple.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ot_server` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ot_server, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ot_server](https://hexdocs.pm/ot_server).
