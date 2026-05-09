import Config
import Dotenvy

source!([".env", System.get_env()])

config :nostrum,
  token: env!("DISCORD_TOKEN",:string!) # na teoria era pra ter uma virgula aqui?
  api_rate_limit_mode::all_events

config :logger, level :info
