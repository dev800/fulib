defmodule Fulib.MockRequestUtilAble do
  @moduledoc """
  用途是，假定一个假的请求，这样只走内部，而不走外部

  ## Examples

  ```
  defmodule Hello.MockRequestUtil do
    use Fulib.MockRequestUtilAble, endpoint: Hello.Endpoint
  end

  # then

  Hello.MockRequestUtil.get("/")
  ```
  """

  defmacro __using__(opts \\ []) do
    quote do
      opts = unquote(opts)

      Module.register_attribute(__MODULE__, :mock_request_util_endpoint, accumulate: false)
      Module.put_attribute(__MODULE__, :mock_request_util_endpoint, Fulib.get(opts, :endpoint))

      Module.eval_quoted(
        __MODULE__,
        quote do
          def get(path_or_action, params_or_body \\ nil, headers \\ []) do
            Fulib.MockRequestUtil.request(
              :get,
              @mock_request_util_endpoint,
              path_or_action,
              params_or_body,
              headers
            )
          end

          def post(path_or_action, params_or_body \\ nil, headers \\ []) do
            Fulib.MockRequestUtil.request(
              :post,
              @mock_request_util_endpoint,
              path_or_action,
              params_or_body,
              headers
            )
          end

          def put(path_or_action, params_or_body \\ nil, headers \\ []) do
            Fulib.MockRequestUtil.request(
              :put,
              @mock_request_util_endpoint,
              path_or_action,
              params_or_body,
              headers
            )
          end

          def patch(path_or_action, params_or_body \\ nil, headers \\ []) do
            Fulib.MockRequestUtil.request(
              :patch,
              @mock_request_util_endpoint,
              path_or_action,
              params_or_body,
              headers
            )
          end

          def delete(path_or_action, params_or_body \\ nil, headers \\ []) do
            Fulib.MockRequestUtil.request(
              :delete,
              @mock_request_util_endpoint,
              path_or_action,
              params_or_body,
              headers
            )
          end

          def options(path_or_action, params_or_body \\ nil, headers \\ []) do
            Fulib.MockRequestUtil.request(
              :options,
              @mock_request_util_endpoint,
              path_or_action,
              params_or_body,
              headers
            )
          end

          def connect(path_or_action, params_or_body \\ nil, headers \\ []) do
            Fulib.MockRequestUtil.request(
              :connect,
              @mock_request_util_endpoint,
              path_or_action,
              params_or_body,
              headers
            )
          end

          def trace(path_or_action, params_or_body \\ nil, headers \\ []) do
            Fulib.MockRequestUtil.request(
              :trace,
              @mock_request_util_endpoint,
              path_or_action,
              params_or_body,
              headers
            )
          end

          def head(path_or_action, params_or_body \\ nil, headers \\ []) do
            Fulib.MockRequestUtil.request(
              :head,
              @mock_request_util_endpoint,
              path_or_action,
              params_or_body,
              headers
            )
          end
        end
      )
    end
  end
end
