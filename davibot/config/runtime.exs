# config/runtime.exs
import Config
import Dotenvy

source!([".env", System.get_env()])

config :nostrum,
  token: env!("DISCORD_TOKEN", :string!)

config :davibot,
  omdb_api_key: env!("OMDB_TOKEN", :string!)

config :gemini_ex,
  api_key: env!("GEMINI_API_KEY", :string!)
