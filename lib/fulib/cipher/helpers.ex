defmodule Fulib.Cipher.Helpers do
  @moduledoc """
    require Fulib.Cipher.Helpers, as: H  # the cool way
  """
  @doc """
    Convenience to get environment bits. Avoid all that repetitive
    `Application.get_env(:myapp, :blah, :blah)` noise.
  """
  def env(key, default \\ nil), do: env(:fulib, key, default)
  def env(app, key, default) do
    app
    |> Application.get_env(:cipher, [])
    |> Fulib.get(key, default)
  end

  @doc """
    Spit to output any passed variable, with location information.
  """
  defmacro spit(obj \\ "", inspect_opts \\ []) do
    quote do
      %{file: file, line: line} = __ENV__
      name = Process.info(self)[:registered_name]

      chain = [
        :bright,
        :red,
        "\n\n#{file}:#{line}",
        :normal,
        "\n     #{inspect(self)}",
        :green,
        " #{name}"
      ]

      msg = inspect(unquote(obj), unquote(inspect_opts))
      if String.length(msg) > 2, do: chain = chain ++ [:red, "\n\n#{msg}"]

      (chain ++ ["\n\n", :reset]) |> IO.ANSI.format(true) |> IO.puts()

      unquote(obj)
    end
  end

  @doc """
    Print to stdout a _TODO_ message, with location information.
  """
  defmacro todo(msg \\ "") do
    quote do
      %{file: file, line: line} = __ENV__

      [:yellow, "\nTODO: #{file}:#{line} #{unquote(msg)}\n", :reset]
      |> IO.ANSI.format(true)
      |> IO.puts()

      :todo
    end
  end
end
