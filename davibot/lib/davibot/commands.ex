defmodule Davibot.Commands do
  @moduledoc """
  Aqui é implementado os comando do davibot
  """
  alias Nostrum.Api.Message
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
    Message.create(cid, embeds: [embed])
  end

end
