defmodule Davibot.Commands.Media do

  alias Nostrum.Api
  alias Davibot.Commands.Helpers

  @doc """
  !plot <nome-do-filme> - Busca dados no OMDB, gera storytelling e avalia notas.
  """
  def plot(%{content: content, channel_id: channel_id}) do
    # Extrai o nome do filme (remove o comando !plot)
    movie_name = content |> String.replace_prefix("!plot", "") |> String.trim()

    if movie_name == "" do
      Helpers.send_error_message(channel_id, "Uso: `!plot <nome do filme>`")
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
          Helpers.send_error_message(channel_id, "Filme não encontrado ou erro na busca.")
      end
    end
  end

  # --- Funções Auxiliares ---

  defp fetch_movie_data(movie_title) do
    encoded_title = URI.encode(movie_title)
    api_key = Application.get_env(:davibot, :omdb_api_key)
    url = "http://www.omdbapi.com/?apikey=#{api_key}&t=#{encoded_title}"
    #IO.inspect(url, label: "OMDB REQUEST URL")

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
  defp generate_ai_content(movie_data) do
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
