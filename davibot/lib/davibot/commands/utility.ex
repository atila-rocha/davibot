defmodule Davibot.Commands.Utility do

  alias Nostrum.Api
  
  @doc """
  Comando !avatar - retorna avatar do usuário com tamanho específico
  """
  def avatar(%{content: content, channel_id: channel_id, guild_id: guild_id} = _msg) do
    content
    |> extract_avatar_args()
    |> case do
      {:ok, user_id, size} ->
        # Agora recebemos member e user
        with {:ok, member, user} <- get_user_info(user_id, guild_id),
             {:ok, avatar_url, user} <- build_avatar_url(member, user, guild_id, size) do
          send_avatar_embed(channel_id, avatar_url, user, size)
        else
          _ -> send_avatar_embed(channel_id, "Não foi possível obter os dados do usuário.")
        end

      :error ->
        valid_sizes = [16, 32, 64, 128, 256, 512, 1024, 2048, 4096]
        sizes_str = Enum.join(valid_sizes, ", ")
        send_avatar_embed(channel_id, "Uso: `!avatar <@usuario> <tamanho>`\n\n**Tamanhos aceitáveis (potências de 2):**\n`#{sizes_str}`")
    end
  end

  @doc """
  Extrai user_id da menção e tamanho do argumento
  Regex: <@123456789> ou <@!123456789>
  """
  defp extract_avatar_args(content) do
    mention_regex = ~r/<@!?(\d+)>/
    # Lista de tamanhos permitidos pela API do Discord
    valid_sizes = [16, 32, 64, 128, 256, 512, 1024, 2048, 4096]

    with [mention, user_id_str] <- Regex.run(mention_regex, content),
         rest <- String.replace(content, mention, ""),
         [size_str] <- Regex.run(~r/\d+/, rest),
         {user_id, _} <- Integer.parse(user_id_str),
         {size, _} <- Integer.parse(size_str),
         # Verifica se o tamanho fornecido está na lista oficial
         true <- size in valid_sizes do
      {:ok, user_id, size}
    else
      _ -> :error
    end
  end


  @doc """
  Obtém info do usuário via API ou Cache
  """
  def get_user_info(user_id, guild_id) do
  # Busca o membro (Cache ou API)
    member_result =
      case Nostrum.Cache.MemberCache.get(guild_id, user_id) do
        {:ok, member} -> {:ok, member}
        {:error, _} -> Nostrum.Api.Guild.member(guild_id, user_id)
      end

    # Busca o usuário (Cache ou API) para ter o objeto User completo
    user_result =
      case Nostrum.Cache.UserCache.get(user_id) do
        {:ok, user} -> {:ok, user}
        {:error, _} -> Nostrum.Api.User.get(user_id)
      end

    case {member_result, user_result} do
      {{:ok, member}, {:ok, user}} -> {:ok, member, user}
      _ -> :error
    end
  end

  # Caso 1: Membro não possui avatar específico no servidor (avatar: nil)
  defp build_avatar_url(%Nostrum.Struct.Guild.Member{avatar: nil}, user, _guild_id, size) do
    url = Nostrum.Struct.User.avatar_url(user) <> "?size=#{size}"
    {:ok, url, user}
  end

  # Caso 2: Membro possui avatar específico no servidor
  defp build_avatar_url(member, user, guild_id, size) do
    url = Nostrum.Struct.Guild.Member.avatar_url(member, guild_id) <> "?size=#{size}"
    {:ok, url, user}
  end

  # Caso 3: Fallback de erro
  defp build_avatar_url(_, _, _), do: :error

  @doc """
  Envia embed com avatar
  """
  defp send_avatar_embed(channel_id, avatar_url, user, size) do
    username = user.username || "Usuário"

    embed = %Nostrum.Struct.Embed{
      title: "🖼️ Avatar de #{username}",
      image: %Nostrum.Struct.Embed.Image{url: avatar_url},
      color: 0x7289DA,
      footer: %Nostrum.Struct.Embed.Footer{text: "Tamanho: #{size}x#{size} px"}
    }

    Api.Message.create(channel_id, embeds: [embed])
  end

  defp send_avatar_embed(channel_id, description) do
    error_embed = %Nostrum.Struct.Embed{
      title: "❌ Erro",
      description: description,
      color: 0xFF0000
    }


    Api.Message.create(channel_id, embeds: [error_embed])
  end

  #-----funções de sair-----

  @doc """
  Comando !sair - envia mensagem e sai do servidor
  """
  def sair(%{content: content, channel_id: channel_id, guild_id: guild_id}) do
    content
    |> String.slice(6..-1)  # Remove "!sair " (6 caracteres)
    |> String.trim()
    |> case do
      "" ->
        error_embed = %Nostrum.Struct.Embed{
          title: "❌ Erro",
          description: "Mensagem não pode ser vazia. Use: `!sair <mensagem>`",
          color: 0xFF0000
        }
        Api.Message.create(channel_id, embeds: [error_embed])

      msg_text ->
        confirm_embed = %Nostrum.Struct.Embed{
          title: "🛑 Davibot está saindo do servidor!",
          description: msg_text,
          color: 0xFF9900
        }

      # Envia mensagem e logga com IO.inspect
      channel_id
      |> Api.Message.create(embeds: [confirm_embed])
      |> tap(fn _ ->
        IO.inspect("Davibot saindo do servidor #{guild_id}: #{msg_text}", label: "SAÍDA")
      end)
      # Sai do servidor e logga
      guild_id
      |> Api.Guild.leave()
      |> tap(fn _ ->
        IO.inspect("Davibot deixou o servidor #{guild_id}", label: "CONFIRMAÇÃO")
      end)
    end
  end

end
