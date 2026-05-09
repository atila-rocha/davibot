defmodule Davibot.Commands do
  @moduledoc """
  Aqui é implementado os comando do davibot
  """
  alias Nostrum.Api
  alias DaviBot.Store

  @doc """
  !calabreso - retona o gif do calma calabreso
  """
  def calabreso(%{channel_id: cid}) do
    Api.create_message(cid, "teste do calabreso!")
  end

end
