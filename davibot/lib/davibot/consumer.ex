defmodule Davibot.Consumer do
  @moduledoc """
  handler de eventos - despacha os comandos
  Na minha visão: Controller para os comandos - recebe as entradas e direciona para as funções commands
  """

  use Nostrum.Consumer
  # alias Nostrum.Api
  require Logger

  alias Davibot.Commands

  # inicia consumer usando o supervisor?
  #def start_link(opts) do
  #  Consumer.start_link(__MODULE__, opts)
  #end
  # def start_link, do: __MODULE__.start_link()

  def handle_event({:MESSAGE_CREATE, msg, _ws}) do
    #IO.puts(msg)
    IO.inspect(msg)
    handle_message(msg)
    #{:noreply, state}
  end

  # Ignora outros eventos (READY, etc.)
  def handle_event(_event, state), do: {:noreply, state}

  # manda o calabreso
  defp handle_message(%{content: "!calabreso"} = msg) do
    Commands.calabreso(msg)
  end

  # Catch-all para mensagens que não são comandos
  defp handle_message(_msg), do: :ok
end
