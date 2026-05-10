# lib/davibot/store.exs
defmodule Davibot.Store do
  @xp_file "priv/repo/xp_data.json"

  @doc "Lê o arquivo JSON e retorna um mapa. Se não existir, retorna mapa vazio."
  def load_xp do
    if File.exists?(@xp_file) do
      @xp_file |> File.read!() |> Jason.decode!()
    else
      %{}
    end
  end

  @doc "Recebe um mapa e salva no arquivo JSON."
  def save_xp(data) do
    File.mkdir_p!(Path.dirname(@xp_file))
    json_content = Jason.encode!(data, pretty: true)
    File.write!(@xp_file, json_content)
  end
end
