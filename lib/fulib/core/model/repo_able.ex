defmodule Fulib.Model.RepoAble do
  defmacro __using__(opts \\ []) do
    quote do
      import Fulib.Model.RepoAble

      @defaulttransaction_retry_times 10

      _opts = unquote(opts)

      Module.eval_quoted(
        __MODULE__,
        quote do
          def fetch(record) do
            if persisted?(record), do: record
          end

          def persisted!(nil), do: nil

          def persisted!(record) do
            if persisted?(record), do: record
          end

          def persisted?(nil), do: false

          def persisted?(%Ecto.Association.NotLoaded{}), do: false

          def persisted?(_), do: true

          def blank?(record), do: not persisted?(record)

          @doc """
          执行数据库的的事务

          ## Params

          * opts

            - `:optimistic_lock_wrapper` 乐观并发控制包装函数 不传时不启用乐观并发控制
            - `:retry_times` 乐观锁失败时的重试次数，默认为 #{@defaulttransaction_retry_times}
          """
          def changeset_transaction(%Ecto.Changeset{} = changeset, transaction_fn, opts \\ []) do
            optimistic_lock_wrapper = opts[:optimistic_lock_wrapper]
            retry_times = opts[:retry_times] || @defaulttransaction_retry_times

            transaction_fn =
              if optimistic_lock_wrapper do
                optimistic_lock_wrapper.(transaction_fn)
              else
                transaction_fn
              end

            retry_fn = fn ->
              __MODULE__.transaction(fn ->
                transaction_fn.()
              end)
            end

            case transaction_retry(retry_fn, retry_times) do
              {:ok, changeset} ->
                changeset

              _ ->
                changeset
            end
          end

          defp transaction_retry(fun, retry_times) do
            if retry_times > 0 do
              try do
                Process.sleep(5)
                fun.()
              rescue
                Ecto.StaleEntryError ->
                  Fulib.log_error([__MODULE__, :transaction_retry, retry_times])
                  transaction_retry(fun, retry_times - 1)
              end
            end
          end

          @doc """
          * opts
            - `:before_fn`          # 初始化一个locker
            - `:after_fn.(locker)`  # 完成事务后更新locker
          """
          def optimistic_lock_wrapper(before_fn, after_fn) do
            fn call_fn ->
              fn ->
                locker = before_fn.()
                callback = call_fn.()

                callback
                |> transaction_ok?
                |> if do
                  after_fn.(locker)
                end

                callback
              end
            end
          end

          def transaction_ok?(callback) do
            case callback do
              %Ecto.Changeset{} = changeset -> changeset.valid?
              {:ok, %Ecto.Changeset{} = changeset} -> changeset.valid?
              _ -> false
            end
          end
        end
      )
    end
  end
end
