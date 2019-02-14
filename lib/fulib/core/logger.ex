defmodule Fulib.Logger do
  require Logger

  @default_options [pretty: true, charlists: false]

  def log_inspect(info, options \\ []) do
    options = @default_options |> Keyword.merge(options)

    _with_stacktrace(options, fn ->
      inspect(info, options)
    end)
  end

  def log_debug(info, options \\ []) do
    _with_stacktrace(options, fn ->
      info |> log_inspect |> Logger.debug(options)
      info
    end)
  end

  def log_info(info, options \\ []) do
    _with_stacktrace(options, fn ->
      info |> log_inspect |> Logger.info(options)
      info
    end)
  end

  def log_warn(info, options \\ []) do
    _with_stacktrace(options, fn ->
      info |> log_inspect |> Logger.warn(options)
      info
    end)
  end

  def log_error(info, options \\ []) do
    options
    |> Fulib.reverse_merge(with_stacktrace: true)
    |> _with_stacktrace(fn ->
      info |> log_inspect |> Logger.error(options)
      info
    end)
  end

  defp _with_stacktrace(options, origin_fn) do
    log = origin_fn.()

    if options[:with_stacktrace] do
      log_stacktrace()
    end

    log
  end

  def log_stacktrace() do
    Logger.error(Exception.format_stacktrace())
  end

  def log(info \\ nil, opts \\ []) do
    case Fulib.get(opts, :level) || Logger.level() do
      :debug -> log_debug(info, opts)
      :info -> log_info(info, opts)
      :warn -> log_warn(info, opts)
      :error -> log_error(info, opts)
      _ -> log_debug(info, opts)
    end
  end

  def log_exception(exception, options \\ []) do
    Exception.format(:error, exception) |> Logger.error(options)
  end

  @doc """
  ## opts

  * `:tag`
  * `:prefix`
  * `:level`
  """
  def ms(function, opts \\ []) do
    start = System.monotonic_time()
    result = function.()
    stop = System.monotonic_time()
    diff = System.convert_time_unit(stop - start, :native, :micro_seconds)
    level = opts[:level] || :info

    log(Fulib.to_array([opts[:tag]]) ++ ["#{opts[:prefix]}in #{formatted_diff(diff)}"],
      level: level
    )

    result
  end

  def formatted_diff(diff) when diff > 1000, do: [diff |> div(1000) |> Integer.to_string(), "ms"]
  def formatted_diff(diff), do: [Integer.to_string(diff), "µs"]
end
