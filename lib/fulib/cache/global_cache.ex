defmodule Fulib.GlobalCache do
  @conf Application.get_env(:fulib, Fulib.GlobalCache) || []
  @namespace Application.get_env(:fulib, :namespaces) |> Fulib.get(:level_cache)

  def namespace, do: @namespace

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
