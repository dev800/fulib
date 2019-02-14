defmodule Fulib.GlobalCache do
  @conf Application.get_env(:fulib, Fulib.GlobalCache) || []

  use Nebulex.Cache,
    otp_app: :fulib,
    adapter:
      (fn ->
         case(@conf[:adapter]) do
           :redis -> NebulexRedisAdapter
           _ -> NebulexRedisAdapter
         end
       end).()

  use Fulib.CacheAble
end
