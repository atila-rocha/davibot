defmodule Davibot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc "Supervisor principal - ponto de entrada do bot"

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Davibot.Consumer
      # Starts a worker by calling: Davibot.Worker.start_link(arg)
      # {Davibot.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Davibot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
