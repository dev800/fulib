defmodule Fulib.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @global_cache_conf Application.get_env(:fulib, Fulib.GlobalCache, [])

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children =
      [
        supervisor(Fulib.LocalCache, [])
      ]
      |> Fulib.if_call(@global_cache_conf[:enable], fn children ->
        children ++ [supervisor(Fulib.GlobalCache, [])]
      end)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Fulib.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
