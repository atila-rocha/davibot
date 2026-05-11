defmodule Davibot.Commands.Helpers do

  alias Nostrum.Api
  
  def send_error_message(channel_id, text) do
    Api.Message.create(channel_id, "❌ #{text}")
  end

  def send_error_embed(channel_id, text) do
    embed = %Nostrum.Struct.Embed{
      title: "❌ Erro",
      description: text,
      color: 0xFF0000
    }
    Api.Message.create(channel_id, embeds: [embed])
  end
end
