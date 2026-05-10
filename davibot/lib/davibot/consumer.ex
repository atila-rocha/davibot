# lib/davibot/consumer.exs
defmodule Davibot.Consumer do
  @moduledoc """
  handler de eventos - despacha os comandos
  Na minha visão: Controller para os comandos - recebe as entradas e direciona para as funções commands
  """

  use Nostrum.Consumer
  # alias Nostrum.Api
  require Logger

  alias Davibot.Commands

  alias Nostrum.Api.Message


  def handle_event({:MESSAGE_CREATE, msg, _ws}) do # TODO: adaptar para que aceite com espaço, e com caixa alta. usar pipe
    # IO.inspect(msg) printa a mensagem no terminal
    handle_message(msg)
  end

  #def handle_event({:MESSAGE_CREATE, msg = %Message{}, _}) do
  #  handle_command(msg)
  #end

  # Ignora outros eventos (READY, etc.)
  def handle_event(_event, state), do: {:noreply, state}

  # manda o calabreso
  defp handle_message(%{content: "!calabreso"} = msg) do
    IO.inspect("CALABRESO MESSAGE ACIONADO")
    Commands.calabreso(msg)
  end

   defp handle_message(%{channel_id: channel_id, content: <<"!roleta-russa", _::binary>>} = msg) do
    IO.inspect("ROLETA RUSSA ACIONADA")
    Commands.roleta_russa(msg)
    |> send_embed(channel_id)
  end

  defp handle_message(%{channel_id: channel_id, content: <<"!roleta_russa", _::binary>>} = msg) do
    IO.inspect("ROLETA RUSSA ACIONADA")
    Commands.roleta_russa(msg)
    |> send_embed(channel_id)
  end

  defp handle_message(%{channel_id: channel_id, content: <<"!roleta russa", _::binary>>} = msg) do
    IO.inspect("ROLETA RUSSA ACIONADA")
    Commands.roleta_russa(msg)
    |> send_embed(channel_id)
  end

  defp handle_message(%{channel_id: channel_id, content: <<"!sair ", _::binary>>} = msg) do
    IO.inspect("SAIDA DO SERVIDOR ACIONADA")
    Commands.sair(msg)
    #{:noreply, state}
  end

  defp handle_message(%{content: <<"!avatar", _::binary>>} = msg) do
    IO.inspect("COMANDO AVATAR ACIONADO")
    Commands.avatar(msg)
  end

  defp handle_message(%{content: <<"!kick", _::binary>>} = msg) do
    IO.inspect("KICK ACIONADO")
    Commands.kick(msg)
  end

  defp handle_message(%{content: <<"!xp", _::binary>>} = msg) do
    IO.inspect("XP COMANDO ACIONADO")
    Commands.xp(msg)
  end


  # Catch-all para mensagens que não são comandos
  defp handle_message(_msg), do: :ok

  defp send_embed(embed, channel_id) do
    Message.create(channel_id, embed: embed)
  end
end
