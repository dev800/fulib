defmodule Fulib.LocalCache do
  use Nebulex.Cache,
    otp_app: :fulib,
    adapter: Nebulex.Adapters.Local

  use Fulib.CacheAble
end
