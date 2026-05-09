defmodule Davibot.Consumer do
  @moduledoc """
  handler de eventos - despacha os comandos
  Na minha visão: Controller para os comandos - recebe as entradas e direciona para as funções commands
  """

  use Nostrum.Consumer
  alias Nostrum.Api
  require Logger

  alias Davibot.Commands

  @impl true
  def handle_event() do
    
  end
end
