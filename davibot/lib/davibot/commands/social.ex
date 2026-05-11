defmodule Davibot.Commands.Social do

    alias Davibot.Commands.Helpers
    alias Nostrum.Api
    alias Davibot.Store

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

  def xp(%{content: content, channel_id: channel_id}) do
    case String.split(content, ~r/\s+/, trim: true) do
      ["!xp"] ->
        handle_list_xp(channel_id)

      ["!xp", mention | _] ->
        handle_add_xp(channel_id, mention)

      _ ->
        Helpers.send_error_message(channel_id, "Uso: `!xp` ou `!xp <@usuario>`")
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
        Helpers.send_error_message(channel_id, "Mencione um usuário válido.")
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

end
