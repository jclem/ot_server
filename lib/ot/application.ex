defmodule OT.Server.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      pool_spec(),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OT.Server.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp pool_spec do
    pool_args = [
      name: {:local, :ot_worker},
      worker_module: OT.Server,
      size: Application.get_env(:ot_server, :pool_size, 5)]

    :poolboy.child_spec(:ot_worker, pool_args)
  end
end
