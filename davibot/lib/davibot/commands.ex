# lib/davibot/commands.exs
defmodule Davibot.Commands do
  @moduledoc """
  Aqui é implementado os comando do davibot
  """
  #alias Nostrum.Api.Message
  alias Nostrum.Api
  alias DaviBot.Store


  @doc """
  !calabreso - retona o gif do calma calabreso
  """
  def calabreso(%{channel_id: cid}) do
    gif_url = "https://imgs.search.brave.com/7jfQ8IDvoNZdLt8966NScrKRAXLXCng7TLKro2Boifc/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9tZWRp/YS50ZW5vci5jb20v/TTRUNl9LSF9HV01B/QUFBTS9jYWxtYS1j/YWxhYnJlc28tY2Fs/bWEtY2FsbWEtY2Fs/YWJyZXNvLmdpZg.gif"
    embed = %Nostrum.Struct.Embed{
      title: "Toma, calabreso",
      image: %Nostrum.Struct.Embed.Image{url: gif_url},
      color: 0x00ff00
    }
    Api.Message.create(cid, embeds: [embed])
  end

  def roleta_russa(msg) do
    #IO.inspect(Api.Guild.members(msg.guild_id, limit: 1000))
    #IO.inspect(Api.Guild.get(msg.guild_id))
    #IO.inspect(Api.Guild.integrations(msg.guild_id))
    #IO.inspect(bot_id = Api.Self.application_information())
    with {:ok, n} <- parse_number(msg.content),
         {:ok, guild} <- Api.Guild.get(msg.guild_id),
         {:ok, members} <- Api.Guild.members(msg.guild_id, limit: 1000),
         {:ok, bot_id} <- get_bot_id(),
         filtered <- filter_members(members, guild.owner_id, bot_id),
         true <- length(filtered) >= n,
         selected <- Enum.shuffle(filtered) |> Enum.take(n),
         :ok <- perform_bans(msg.guild_id, selected) do
      IO.inspect("Roleta Russa: banned #{n} members in guild #{msg.guild_id}")
      success_embed(n)
    else
      {:error, reason} -> error_embed(reason)
      false -> error_embed("Not enough eligible members")
    end
  end

  @doc """
  Obtém o bot_id via Api.Self.application_information()
  Retorna {:ok, bot_id} ou {:error, reason}
  """
  def get_bot_id do
    with {:ok, %{bot: %{id: bot_id}}} <- Api.Self.application_information() do
      {:ok, bot_id}
    else
      _ -> {:error, "Falha ao obter ID do bot"}
    end
  end

  defp parse_number(content) do
    case Regex.run(~r/!(roleta[-_\s]+russa)\s+(\d+)/i, String.trim(content)) do
      [_, _, number_str] ->
        case Integer.parse(number_str) do
          {n, ""} when n >= 1 and n <= 500 ->
            {:ok, n}
          _ ->
            {:error, "Número inválido. Deve ser inteiro entre 1 e 500."}
        end
      _ ->
        {:error, "Formato inválido. Use: !roleta-russa <número>"}
    end
  end


  def filter_members(members, owner_id, bot_id) do
    members
    |> Enum.filter(&(&1.user_id != owner_id))
    |> Enum.filter(&(&1.user_id != bot_id))
  end

  defp perform_bans(guild_id, selected) do
    Enum.reduce_while(selected, :ok, fn member, _acc ->
      case ban_member(guild_id, member) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp ban_member(guild_id, member) do
    # Ajustado para retornar :ok puro conforme o padrão da API do Nostrum
    case Api.Guild.ban_member(guild_id, member.user_id, 0, "roleta russa do davi brito") do
      {:ok} ->
        IO.inspect("Banned user #{member.user_id}")
        :ok
      {:error, reason} ->
        IO.inspect("Failed to ban #{member.user_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp success_embed(n) do
    %Nostrum.Struct.Embed{
      title: "🎰 Roleta Russa!",
      description: "💥 Banidos #{n} membros aleatórios com sucesso!",
      color: 0xFF4444
    }
  end

  defp error_embed(reason) do
    %Nostrum.Struct.Embed{
      title: "❌ Erro na Roleta Russa",
      description: "Falha na operação: #{inspect(reason)}",
      color: 0xFF0000
    }
  end

end
