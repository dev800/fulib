defmodule Fulib.String do
  @crypto_secret Application.get_env(:fulib, :crypto_secret) || "ca1d53450d12ee57f900ddc1814bb7c4"

  @doc """
  使用liquid进行渲染

  urls:

  * https://github.com/bettyblocks/liquid-elixir
  * https://hex.pm/packages/liquid
  * https://shopify.github.io/liquid/basics/introduction/

  """
  def liquid_render(template \\ "", data \\ %{}) do
    template
    |> Liquid.Template.parse()
    |> Liquid.Template.render(Fulib.Map.string_keys_deep!(data))
  end

  def liquid_render!(template \\ "", data \\ %{}) do
    template
    |> liquid_render(data)
    |> case do
      {:ok, rendered, _} -> rendered
      _ -> nil
    end
  end

  @doc """
  获取字符串的长度

  * 英文字符算1位(半角)
  * 中文字符算2位(全角)
  * emoji算2位
  """
  def chars_length(string, opts \\ []) do
    string
    |> String.split("", trim: Fulib.get(opts, :trim, true))
    |> Enum.reduce(0, fn char, length ->
      current_length =
        case char |> byte_size() do
          1 -> 1
          _ -> 2
        end

      length + current_length
    end)
  end

  def recase(value), do: value
  def recase(value, :camel), do: Recase.to_camel(value)
  def recase(value, :constant), do: Recase.to_constant(value)
  def recase(value, :dot), do: Recase.to_dot(value)
  def recase(value, :kebab), do: Recase.to_kebab(value)
  def recase(value, :pascal), do: Recase.to_pascal(value)
  def recase(value, :snake), do: Recase.to_snake(value)
  def recase(value, :path), do: Recase.to_path(value)
  def recase(value, _type), do: value

  def parse(value \\ nil), do: value |> to_string()

  def html_escape(nil), do: ""

  def html_escape(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end

  ################## truncate ##############################
  def truncate(text), do: truncate(text, [])
  def truncate(text, do: block), do: truncate(text, [], do: block)
  def truncate(text, opts) when is_map(opts) or is_list(opts), do: truncate(text, opts, do: nil)
  def truncate(nil, _options, do: _block), do: ""

  def truncate(text, opts, do: block) when is_map(opts) or is_list(opts) do
    text_length = opts |> Fulib.get(:length, 32, 32) |> Fulib.to_i()
    html_escaped = opts |> Fulib.get(:html_escape, false, false) |> Fulib.to_boolean()

    if String.length(text) < text_length do
      if html_escaped do
        "#{html_escape(text)}"
      else
        text
      end
    else
      omission = opts |> Fulib.get(:omission, "...", "...") |> Fulib.to_s()
      origin_text = String.slice(text, 0..(text_length - String.length(omission))) <> omission

      if html_escaped do
        "#{html_escape(origin_text)}#{block}"
      else
        "#{origin_text}#{block}"
      end
    end
  end

  ################# END truncate #############################

  #### Begin blank? ######################
  def blank?(value) when is_list(value) do
    value == []
  end

  def blank?(value) when is_map(value) do
    value == %{}
  end

  def blank?(~r//), do: true

  def blank?(""), do: true
  def blank?(nil), do: true

  def blank?(value) when is_tuple(value) do
    value == {}
  end

  def blank?(value) when is_binary(value) or is_atom(value) do
    trim(value) == ""
  end

  def blank?(_), do: false

  #### Begin present? #####################
  def present?(value), do: not blank?(value)

  def trim(value) do
    value |> parse |> String.trim()
  end

  def length(value, opts \\ []) do
    if opts[:trim] do
      value |> parse |> String.trim() |> String.length()
    else
      value |> parse |> String.length()
    end
  end

  def hmac_sha256(str), do: hmac_sha256(@crypto_secret, str)

  def hmac_sha256(secret, str) do
    :crypto.hmac(:sha256, secret, Fulib.to_s(str)) |> Base.encode16()
  end

  def hmac_sha512(str), do: hmac_sha512(@crypto_secret, str)

  def hmac_sha512(secret, str) do
    :crypto.hmac(:sha512, secret, Fulib.to_s(str)) |> Base.encode16()
  end

  def sha256(str) do
    :crypto.hash(:sha256, Fulib.to_s(str)) |> Base.encode16(case: :lower)
  end

  def sha512(str) do
    :crypto.hash(:sha512, Fulib.to_s(str)) |> Base.encode16(case: :lower)
  end

  def md5(str) do
    :crypto.hash(:md5, Fulib.to_s(str)) |> Base.encode16(case: :lower)
  end

  def loop_chars(chars, count \\ 1, gap \\ "")

  def loop_chars(chars, count, gap) when count >= 1 do
    1..count
    |> Enum.map(fn _ -> chars end)
    |> Enum.join(gap)
  end

  def loop_chars(_chars, _count, _gap), do: ""

  defdelegate pluralize(word), to: Fulib.String.Inflector
  defdelegate singularize(word), to: Fulib.String.Inflector

  def words_filter(value) do
    Fulib.Const.words_regex()
    |> Regex.scan(value |> Fulib.to_s())
    |> List.flatten()
    |> Enum.join()
  end

  def summary(nil), do: ""

  def summary(string) do
    string
    # more space
    |> String.replace(~r/(\t|\r|\n)/, " ")
    |> String.replace(~r/(\s{2,})/, " ")
    # image
    |> String.replace(~r/\!\[.*?\]\(.*?\)/, "")
    # link
    |> String.replace(~r/\[(.*?)\]\(.*?\)/, "\\1")
    # leading formats
    |> String.replace(~r/(^|\n)(>\s*|#+\s*|\*\s+)/, "\\1")
    |> String.trim()
  end

  def percent_format(value) do
    "%.2f" |> Fulib.Printf.sprintf([value * 100]) |> String.replace(~r"\.?+0+$", "", global: true)
  end

  def price_format(value) do
    "%.2f" |> Fulib.Printf.sprintf([value]) |> String.replace(~r"\.?+0+$", "", global: true)
  end
end
