# config/runtime.exs
import Config
import Dotenvy

source!([".env", System.get_env()])

config :nostrum,
  token: env!("DISCORD_TOKEN", :string!)
