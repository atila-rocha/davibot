defmodule Davibot.Commands.Moderation do

  alias Nostrum.Api
  alias Davibot.Commands.Helpers

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
  defp get_bot_id() do
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

  #----- funções de kick --------

  defp extract_kick_args(content) do
    # Divide a string por espaços
    # Ex: ["!kick", "<@123456789>", "taoff"]
    args = String.split(content, ~r/\s+/, trim: true)

    case args do
      [_comando, mention | rest] ->
        # Tenta capturar o ID da menção no SEGUNDO elemento da lista
        case Regex.run(~r/<@!?(\d+)>/, mention) do
          [_, user_id_str] ->
            reason = if rest == [], do: "Motivo não especificado", else: Enum.join(rest, " ")
            {:ok, String.to_integer(user_id_str), reason}

          _ ->
            {:error, "O primeiro argumento após o comando deve ser uma menção válida (ex: <@user>)."}
        end

      _ ->
        {:error, "Uso correto: `!kick <@usuario> <motivo>`"}
    end
  end

def kick(message) do
  with {:ok, user_id, reason} <- extract_kick_args(message.content),
       guild_id when not is_nil(guild_id) <- message.guild_id do
    case Api.Guild.kick_member(guild_id, user_id, reason) do
      {:ok} ->
        embed = %Nostrum.Struct.Embed{
          title: "✅ Sucesso!",
          description: "O usuário <@#{user_id}> foi kickado do servidor.\n**Motivo:** \"#{reason}\"",
          color: 0x00FF00
        }
        Api.Message.create(message.channel_id, embed: embed)

      {:error, error} ->
        Helpers.send_error_embed(message.channel_id, "Falha ao kickar usuário: #{inspect(error)}")
    end
    else
      {:error, msg} ->
        Helpers.send_error_embed(message.channel_id, msg)

      nil ->
        Helpers.send_error_embed(message.channel_id, "Este comando só pode ser usado em servidores.")

      _ ->
        Helpers.send_error_embed(message.channel_id, "Erro inesperado.")
    end
  end

end
