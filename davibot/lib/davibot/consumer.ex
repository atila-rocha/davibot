# lib/davibot/consumer.ex
defmodule Davibot.Consumer do
  @moduledoc """
  Handler de eventos - Despacha os comandos centralizadamente.
  """

  use Nostrum.Consumer
  alias Davibot.Commands
  alias Nostrum.Api.Message
  require Logger

  def handle_event({:MESSAGE_CREATE, msg, _ws}) do
    # 1. Normalização: Coloca tudo em minúsculo e remove espaços extras nas pontas
    # Isso resolve o problema de "!PLOT" ou "!xp  "
    content_lower = msg.content |> String.downcase() |> String.trim()

    # 2. Direcionamento via cond (Roteador)
    cond do
      # Comandos exatos
      content_lower == "!calabreso" ->
        Commands.calabreso(msg)

      # Comandos que aceitam variações (Roleta)
      # O String.starts_with? aceita uma LISTA de strings
      String.starts_with?(content_lower, ["!roleta-russa", "!roleta_russa", "!roleta russa"]) ->
        IO.inspect("ROLETA RUSSA ACIONADA")
        Commands.Moderation.roleta_russa(msg)
        |> send_embed(msg.channel_id)

      # Comandos com argumentos (Prefixos)
      String.starts_with?(content_lower, "!sair") ->
        Commands.Utility.sair(msg)

      String.starts_with?(content_lower, "!avatar") ->
        Commands.Utility.avatar(msg)

      String.starts_with?(content_lower, "!kick") ->
        Commands.Moderation.kick(msg)

      String.starts_with?(content_lower, "!xp") ->
        Commands.Social.xp(msg)

      String.starts_with?(content_lower, "!plot") ->
        Commands.Media.plot(msg)

      # Caso não seja nenhum comando
      true ->
        :ignore
    end
  end

  # Ignora outros eventos (READY, etc.)
  def handle_event(_event, _state), do: :ok

  # Função auxiliar para enviar embeds (padronizada para lista)
  defp send_embed(embed, channel_id) do
    Message.create(channel_id, embeds: [embed])
  end
end
