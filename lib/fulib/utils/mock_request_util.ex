defmodule Fulib.MockRequestUtil do
  # https://github.com/phoenixframework/phoenix/blob/master/lib/phoenix/test/conn_test.ex

  @doc """
  Creates a connection to be used in upcoming requests.
  """
  @spec build_conn() :: Plug.Conn.t()
  def build_conn() do
    build_conn(:get, "/", nil)
  end

  def build_conn(method, path) do
    build_conn(method, path, %{}, %{})
  end

  def build_conn(method, path, params_or_body) do
    build_conn(method, path, params_or_body, %{})
  end

  def build_conn(method, path, params_or_body, _headers) do
    Plug.Adapters.Test.Conn.conn(%Plug.Conn{}, method, path, params_or_body)
    |> Plug.Conn.put_private(:plug_skip_csrf_protection, true)
    |> Plug.Conn.put_private(:phoenix_recycled, true)
  end

  def request(method, endpoint, path_or_action, params_or_body, headers) do
    method
    |> build_conn(path_or_action, params_or_body)
    |> Fulib.if_call(Fulib.present?(headers), fn conn ->
      headers
      |> Enum.reduce(conn, fn {k, v}, conn ->
        conn |> Plug.Conn.put_req_header(k, v)
      end)
    end)
    |> dispatch(endpoint, method, path_or_action, params_or_body)
    |> response
  end

  def dispatch(conn, endpoint, method, path_or_action, params_or_body \\ nil)

  def dispatch(%Plug.Conn{} = conn, endpoint, method, path_or_action, params_or_body) do
    if is_nil(endpoint) do
      raise "no @endpoint set in test case"
    end

    if is_binary(params_or_body) and is_nil(List.keyfind(conn.req_headers, "content-type", 0)) do
      raise ArgumentError,
            "a content-type header is required when setting " <>
              "a binary body in a test connection"
    end

    conn
    |> ensure_recycled()
    |> dispatch_endpoint(endpoint, method, path_or_action, params_or_body)
    |> Plug.Conn.put_private(:phoenix_recycled, false)
    |> from_set_to_sent()
  end

  def dispatch(conn, _endpoint, method, _path_or_action, _params_or_body) do
    raise ArgumentError,
          "expected first argument to #{method} to be a " <> "%Plug.Conn{}, got #{inspect(conn)}"
  end

  defp dispatch_endpoint(conn, endpoint, method, path, params_or_body) when is_binary(path) do
    conn
    |> Plug.Adapters.Test.Conn.conn(method, path, params_or_body)
    |> endpoint.call(endpoint.init([]))
  end

  defp dispatch_endpoint(conn, endpoint, method, action, params_or_body) when is_atom(action) do
    conn
    |> Plug.Adapters.Test.Conn.conn(method, "/", params_or_body)
    |> endpoint.call(endpoint.init(action))
  end

  defp from_set_to_sent(%Plug.Conn{state: :set} = conn), do: Plug.Conn.send_resp(conn)
  defp from_set_to_sent(conn), do: conn

  @doc """
  Puts a request cookie.
  """
  @spec put_req_cookie(Plug.Conn.t(), binary, binary) :: Plug.Conn.t()
  defdelegate put_req_cookie(conn, key, value), to: Plug.Test

  @doc """
  Deletes a request cookie.
  """
  @spec delete_req_cookie(Plug.Conn.t(), binary) :: Plug.Conn.t()
  defdelegate delete_req_cookie(conn, key), to: Plug.Test

  @doc """
  Returns the content type as long as it matches the given format.

  ## Examples

      # Assert we have an html repsonse with utf-8 charset
      assert response_content_type(conn, :html) =~ "charset=utf-8"

  """
  @spec response_content_type(Plug.Conn.t(), atom) :: String.t() | no_return
  def response_content_type(conn, format) when is_atom(format) do
    case Plug.Conn.get_resp_header(conn, "content-type") do
      [] ->
        raise "no content-type was set, expected a #{format} response"

      [h] ->
        if response_content_type?(h, format) do
          h
        else
          raise "expected content-type for #{format}, got: #{inspect(h)}"
        end

      [_ | _] ->
        raise "more than one content-type was set, expected a #{format} response"
    end
  end

  defp response_content_type?(header, format) do
    case parse_content_type(header) do
      {part, subpart} ->
        format = Atom.to_string(format)

        format in MIME.extensions(part <> "/" <> subpart) or format == subpart or
          String.ends_with?(subpart, "+" <> format)

      _ ->
        false
    end
  end

  defp parse_content_type(header) do
    case Plug.Conn.Utils.content_type(header) do
      {:ok, part, subpart, _params} ->
        {part, subpart}

      _ ->
        false
    end
  end

  def response(%Plug.Conn{status: status, resp_body: body}) do
    {status, body}
  end

  @doc """
  Returns the location header from the given redirect response.

  Raises if the response does not match the redirect status code
  (defaults to 302).

  ## Examples

      assert redirected_to(conn) =~ "/foo/bar"
      assert redirected_to(conn, 301) =~ "/foo/bar"
      assert redirected_to(conn, :moved_permanently) =~ "/foo/bar"
  """
  @spec redirected_to(Plug.Conn.t(), status :: non_neg_integer) :: Plug.Conn.t()
  def redirected_to(conn, status \\ 302)

  def redirected_to(%Plug.Conn{state: :unset}, _status) do
    raise "expected connection to have redirected but no response was set/sent"
  end

  def redirected_to(%Plug.Conn{status: status} = conn, status) do
    location = Plug.Conn.get_resp_header(conn, "location") |> List.first()
    location || raise "no location header was set on redirected_to"
  end

  def redirected_to(conn, status) do
    raise "expected redirection with status #{status}, got: #{conn.status}"
  end

  @spec recycle(Plug.Conn.t()) :: Plug.Conn.t()
  def recycle(conn) do
    build_conn()
    |> Plug.Test.recycle_cookies(conn)
    |> copy_headers(conn.req_headers, ~w(accept))
  end

  defp copy_headers(conn, headers, copy) do
    headers = for {k, v} <- headers, k in copy, do: {k, v}
    %{conn | req_headers: headers ++ conn.req_headers}
  end

  @doc """
  Ensures the connection is recycled if it wasn't already.

  See `recycle/1` for more information.
  """
  @spec ensure_recycled(Plug.Conn.t()) :: Plug.Conn.t()
  def ensure_recycled(conn) do
    if conn.private[:phoenix_recycled] do
      conn
    else
      recycle(conn)
    end
  end

  @spec bypass_through(Plug.Conn.t()) :: Plug.Conn.t()
  def bypass_through(conn) do
    Plug.Conn.put_private(conn, :phoenix_bypass, :all)
  end

  @doc """
  Calls the Endpoint and bypasses Router match.

  See `bypass_through/1`.
  """
  @spec bypass_through(Conn.t(), module, :atom | list) :: Conn.t()
  def bypass_through(conn, router, pipelines \\ []) do
    Plug.Conn.put_private(conn, :phoenix_bypass, {router, List.wrap(pipelines)})
  end
end
