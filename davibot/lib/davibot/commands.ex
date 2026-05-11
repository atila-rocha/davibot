# lib/davibot/commands.exs
defmodule Davibot.Commands do
  @moduledoc """
  Aqui é implementado os comando do davibot
  """
  #alias Nostrum.Api.Message
  alias Nostrum.Api

  alias Davibot.Store

  #@omdb_api_key Application.compile_env(:davibot, :omdb_api_key)


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
        send_error_embed(message.channel_id, "Falha ao kickar usuário: #{inspect(error)}")
    end
    else
      {:error, msg} ->
        send_error_embed(message.channel_id, msg)

      nil ->
        send_error_embed(message.channel_id, "Este comando só pode ser usado em servidores.")

      _ ->
        send_error_embed(message.channel_id, "Erro inesperado.")
    end
  end

  defp send_error_embed(channel_id, text) do
    embed = %Nostrum.Struct.Embed{
      title: "❌ Erro",
      description: text,
      color: 0xFF0000
    }
    Api.Message.create(channel_id, embeds: [embed])
  end

  def xp(%{content: content, channel_id: channel_id}) do
    case String.split(content, ~r/\s+/, trim: true) do
      ["!xp"] ->
        handle_list_xp(channel_id)

      ["!xp", mention | _] ->
        handle_add_xp(channel_id, mention)

      _ ->
        send_error_message(channel_id, "Uso: `!xp` ou `!xp <@usuario>`")
    end
  end

  # Regra de negócio: Adicionar XP
  defp handle_add_xp(channel_id, mention) do
    case Regex.run(~r/<@!?(\d+)>/, mention) do
      [_, user_id] ->
        data = Store.load_xp()
        new_xp = Map.get(data, user_id, 0) + 1

        data
        |> Map.put(user_id, new_xp)
        |> Store.save_xp()

        Api.Message.create(channel_id, "⭐ <@#{user_id}> subiu para **#{new_xp} XP**!")

      _ ->
        send_error_message(channel_id, "Mencione um usuário válido.")
    end
  end

  # Regra de negócio: Listar Ranking
  defp handle_list_xp(channel_id) do
    data = Store.load_xp()

    if map_size(data) == 0 do
      Api.Message.create(channel_id, "Ranking vazio!")
    else
      ranking = data
      |> Enum.sort_by(fn {_id, xp} -> xp end, :desc)
      |> Enum.map_join("\n", fn {id, xp} -> "• <@#{id}>: **#{xp} XP**" end)

      embed = %Nostrum.Struct.Embed{
        title: "🏆 Ranking de XP",
        description: ranking,
        color: 0xFFD700
      }
      Api.Message.create(channel_id, embeds: [embed])
    end
  end

  defp send_error_message(channel_id, text) do
    Api.Message.create(channel_id, "❌ #{text}")
  end

  @doc """
  !plot <nome-do-filme> - Busca dados no OMDB, gera storytelling e avalia notas.
  """
  def plot(%{content: content, channel_id: channel_id}) do
    # Extrai o nome do filme (remove o comando !plot)
    movie_name = content |> String.replace_prefix("!plot", "") |> String.trim()

    if movie_name == "" do
      send_error_message(channel_id, "Uso: `!plot <nome do filme>`")
    else
      Api.Message.create(channel_id, "Aguarde! Estou procurando pelo filme")
      # 1. Busca os dados (Aqui você chamaria sua função de API ou IA)
      # Simulando o retorno do JSON da OMDB
      case fetch_movie_data(movie_name) do
        {:ok, movie_data} ->
          # 2. IA gera o Storytelling e a Avaliação
          ai_response = generate_ai_content(movie_data)

          # 3. Envia o Embed final
          send_plot_embed(channel_id, movie_data, ai_response)

        {:error, _reason} ->
          send_error_message(channel_id, "Filme não encontrado ou erro na busca.")
      end
    end
  end

  # --- Funções Auxiliares ---

  def fetch_movie_data(movie_title) do
    encoded_title = URI.encode(movie_title)
    api_key = Application.get_env(:davibot, :omdb_api_key)
    url = "http://www.omdbapi.com/?apikey=#{api_key}&t=#{encoded_title}"
    IO.inspect(url, label: "OMDB REQUEST URL")

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, movie_data} ->
            if movie_data["Response"] == "True" do
              {:ok, movie_data}
            else
              {:error, movie_data["Error"] || "Movie not found"}
            end
          {:error, reason} ->
            {:error, "Failed to decode JSON: #{inspect(reason)}"}
        end

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        IO.inspect(status, label: "OMDB HTTP ERROR STATUS")
        {:error, "HTTP #{status}: #{body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason, label: "OMDB CONNECTION ERROR")
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  @doc """
  Recebe os dados do OMDB e usa o Gemini para gerar storytelling e avaliação.
  """
  def generate_ai_content(movie_data) do
    # Preparamos os dados para o prompt
    movie_info = Jason.encode!(movie_data)

    prompt = """
    Você é um contador de histórias e crítico de cinema.
    Com base nos seguintes dados do filme vindos da API OMDB:
    #{movie_info}

    Sua tarefa:
    1. Crie um storytelling curto e envolvente (máximo 500 caracteres) sobre o enredo.
    2. Faça uma avaliação dizendo se o filme é bom ou não, baseando-se estritamente nas notas do Rotten Tomatoes, IMDb e Metacritic presentes nos dados.

    """

    # Chamada ao Gemini (ajuste o modelo conforme sua preferência)
    case Gemini.generate(prompt) do
      {:ok, response} ->
        case Gemini.extract_text(response) do
          {:ok, text} -> text
          _ -> "Erro ao extrair o texto da resposta da IA."
        end

      {:error, reason} ->
        IO.inspect(reason, label: "ERRO GEMINI")
        {"Não foi possível gerar a história agora.", "Confira as notas abaixo."}
    end
  end

  # Ajuste na função de envio para aceitar o texto consolidado da IA
  defp send_plot_embed(channel_id, movie, ai_text) do
    embed = %Nostrum.Struct.Embed{
      title: "🎬 #{movie["Title"]} (#{movie["Year"]})",
      description: ai_text,
      color: 0x1ABC9C,
      footer: %Nostrum.Struct.Embed.Footer{text: "Davibot Movie Storyteller"}
    }

    Api.Message.create(channel_id, embeds: [embed])
  end


end
