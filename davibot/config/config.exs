# config/config.exs
import Config
#import Dotenvy

#source!([".env", System.get_env()])

config :nostrum,
  #token: env!("DISCORD_TOKEN", :string!),
  gateway_intents: :all,
  ffmpeg: false
  #api_rate_limit_mode: :all_events

#config :logger,
#  level: :info
