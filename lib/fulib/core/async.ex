defmodule Fulib.Async do
  @moduledoc """
  异步方法
  """

  @default_timeout 5_000

  def pmap(collection, func, timeout \\ @default_timeout) do
    collection
    |> Enum.map(fn x -> Task.async(fn -> func.(x) end) end)
    |> Enum.map(&Task.await(&1, timeout))
  end

  @doc """
  异步提交，有一个成功返回则停止

  ## Params

  * list 异步提交的参数列表
  * fun_do 异步提交的函数
  * opts
    * take :: integer 从 list 中取出前多少个，默认全部
    * check_frequency :: integer 检查完成的频率，默认 50 毫秒
    * timeout :: integer 默认 #{@default_timeout} 毫秒

  ## Examples

  ```
  iex> NetProxyLogic.get_list(https: uri.scheme == "https")
  |> prequest(fn(net_proxy) ->
    opts |> Fulib.put(:net_proxy, net_proxy) |> do_request()
  en3d, take：5)
  ```
  """
  def prequest(list, fun_do, opts) when is_list(list) do
    init = Fulib.SecureRandom.uuid() |> String.to_atom()
    Agent.start_link(fn -> init end, name: init)
    take = opts[:take] || length(list)

    tasks =
      list
      |> Enum.take(take)
      |> Enum.map(fn args ->
        Task.async(fn ->
          result = fun_do.(args)
          Agent.update(init, fn _state -> result end)
        end)
      end)

    result = sync_wait(init, opts, opts[:timeout] || @default_timeout)

    # 杀掉未完成进程
    tasks
    |> Enum.each(fn task ->
      Task.shutdown(task, :brutal_kill)
    end)

    result
  end

  defp sync_wait(init, opts, timeout) when timeout > 0 do
    state = Agent.get(init, fn state -> state end)

    {state_code, state} =
      if is_tuple(state) do
        state
      else
        {:ok, state}
      end

    if state == init || state_code != :ok do
      sleep = opts[:check_frequency] || 20
      Process.sleep(sleep)
      sync_wait(init, opts, timeout - sleep)
    else
      {:ok, state}
    end
  end

  defp sync_wait(_init, _opts, _timeout) do
    {:error, :timeout}
  end
end
