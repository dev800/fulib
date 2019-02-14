# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :fulib, Fulib.LocalCache, gc_interval: 86_400

config :fulib, Fulib.GlobalCache,
  enable: true,
  adapter: :redis,
  pools: [
    primary: [
      host: System.get_env("REDIS_HOST") || "127.0.0.1",
      port: (System.get_env("REDIS_PORT") || "6379") |> String.to_integer(),
      pool_size: (System.get_env("REDIS_POOL") || "10") |> String.to_integer(),
      password: (System.get_env("REDIS_PASSWORD") || nil)
    ]
  ]

config :fulib, :translator_domains,
  models: "models",
  model_fields: "model_fields",
  model_errors: "model_errors"

config :fulib, :cipher,
  keyphrase: "badffcefc86ab1044dcaad04833d6b42",
  ivphrase: "c6ba01e874a2310c4de3def1b97c5d89"

# 默认的时区
config :fulib, :default_timezone, "Asia/Shanghai"
# 东八区
config :fulib, :default_utc_offset, 28_800
# 默认中文
config :fulib, Fulib.Gettext, default_locale: "zh_CN"

if File.exists?("#{__DIR__}/#{Mix.env()}.exs") do
  import_config "#{Mix.env()}.exs"
end
