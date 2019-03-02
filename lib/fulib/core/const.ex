defmodule Fulib.Const do
  #### http://elixir-lang.org/docs/master/elixir/Regex.html
  @ip_regex ~r"^(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])$"
  @email_regex ~r"\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z"
  @pure_number_regex ~r"\A[0-9]*\z"
  @integer_regex ~r"^-?[1-9]\d*$"
  @words_regex ~r/[\w-_0-9]+/u
  @email_regex ~r"\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z"
  @mobile_number_formats [
    cn: %{
      length: 11,
      regex: ~r/^(1[3-9][0-9])\d{8}$/u
    }
  ]
  @website_url_regex ~r"^((http|https)\:\/\/|[a-zA-Z0-9\.\-]+\.)[0-9a-zA-Z]([-.\w]*[0-9a-zA-Z])*(:(0-9)*)*(\/?)([a-zA-Z0-9\-\=\&\.\?\,\'\/\\\+&amp;%\$#_]*)?"

  @spider_regex ~r(spider|bot|crawler|ysearch\/slurp)

  @top_domains [
    "arpa",
    "asia",
    "biz",
    "cam",
    "cat",
    "com",
    "coop",
    "edu",
    "gov",
    "int",
    "info",
    "jobs",
    "media",
    "mil",
    "mobi",
    "mtn",
    "museum",
    "name",
    "net",
    "pro",
    "travel",
    "wtf",
    "win",
    "xxx",
    "xyz",
    "singles",
    "tel",
    "org",
    "as",
    "bi",
    "ca",
    "co",
    "ed",
    "go",
    "in",
    "jo",
    "me",
    "mi",
    "mo",
    "mt",
    "mu",
    "na",
    "ne",
    "or",
    "pr",
    "te",
    "tr",
    "wt",
    "wi",
    "xx",
    "xy",
    "si",
    "cn",
    "hk",
    "tw",
    "eg",
    "sa",
    "lk",
    "th",
    "ac",
    "ad",
    "af",
    "ag",
    "ai",
    "al",
    "am",
    "an",
    "ao",
    "aq",
    "at",
    "au",
    "aw",
    "az",
    "ba",
    "bb",
    "bd",
    "be",
    "bf",
    "bg",
    "bh",
    "bj",
    "bm",
    "bn",
    "bo",
    "br",
    "bs",
    "bt",
    "bv",
    "bw",
    "by",
    "bz",
    "cc",
    "cd",
    "cf",
    "cg",
    "ch",
    "ci",
    "ck",
    "cl",
    "cm",
    "cr",
    "cs",
    "cu",
    "cv",
    "cx",
    "cy",
    "cz",
    "de",
    "dj",
    "dk",
    "dm",
    "do",
    "dz",
    "ec",
    "ee",
    "eh",
    "er",
    "es",
    "et",
    "fi",
    "fj",
    "fk",
    "fm",
    "fo",
    "fr",
    "ga",
    "gb",
    "gd",
    "ge",
    "gf",
    "gh",
    "gi",
    "gl",
    "gm",
    "gn",
    "gp",
    "gq",
    "gr",
    "gs",
    "gt",
    "gu",
    "gw",
    "gy",
    "hm",
    "hn",
    "hr",
    "ht",
    "hu",
    "id",
    "ie",
    "il",
    "io",
    "iq",
    "ir",
    "is",
    "it",
    "jm",
    "jp",
    "ke",
    "kg",
    "kh",
    "ki",
    "km",
    "kn",
    "kp",
    "kr",
    "kw",
    "ky",
    "kz",
    "la",
    "lb",
    "lc",
    "li",
    "lr",
    "ls",
    "lt",
    "lu",
    "lv",
    "ly",
    "ma",
    "mc",
    "md",
    "mg",
    "mh",
    "mk",
    "ml",
    "mm",
    "mn",
    "mp",
    "mq",
    "mr",
    "ms",
    "mv",
    "mw",
    "mx",
    "my",
    "mz",
    "nc",
    "nf",
    "ng",
    "ni",
    "nl",
    "no",
    "np",
    "nr",
    "nu",
    "nz",
    "om",
    "pa",
    "pe",
    "pf",
    "pg",
    "ph",
    "pk",
    "pl",
    "pm",
    "pn",
    "pt",
    "pw",
    "py",
    "qa",
    "re",
    "ro",
    "ru",
    "rw",
    "sb",
    "sc",
    "sd",
    "se",
    "sg",
    "sh",
    "sj",
    "sk",
    "sl",
    "sm",
    "sn",
    "so",
    "sr",
    "ss",
    "st",
    "sv",
    "sx",
    "sy",
    "sz",
    "tc",
    "td",
    "tf",
    "tg",
    "tj",
    "tk",
    "tm",
    "tn",
    "to",
    "tp",
    "tt",
    "tv",
    "tz",
    "ua",
    "ug",
    "uk",
    "us",
    "uy",
    "uz",
    "va",
    "vc",
    "ve",
    "vg",
    "vi",
    "vn",
    "vu",
    "wf",
    "ws",
    "ye",
    "yt",
    "yu",
    "za",
    "zm",
    "zr",
    "zw",
    "ps",
    "tl",
    "gg",
    "gz",
    "im",
    "um",
    "eu",
    "je",
    "ax",
    "cw",
    "rs",
    "su",
    "rf",
    "bl",
    "bq",
    "mf",
    "bu",
    "dd",
    "ia",
    "ae",
    "ar"
  ]

  @scan_url_regex [
    "((https?|mailto|thunder|ftp|sftp|svn):\/\/[-A-Za-z0-9+&@#\/%\?=~_|!:,.;]+[-A-Za-z0-9+&@#\/%=~_|])|",
    "([a-zA-Z0-9\.\-]+)",
    "(\\.(#{@top_domains |> Enum.join("|")}))",
    "(:(0-9)*)*(\/[a-zA-Z0-9\-\=\&\.\?\,\'\/\\\+&amp;%\$#_]*)?"
  ]

  def spider_regex, do: @spider_regex

  @doc "IO地址的正则表达式"
  def ip_regex, do: @ip_regex

  def ip_match?(ip) do
    Regex.match?(@ip_regex, ip)
  end

  @doc "电子邮箱的正则表达式"
  def email_regex, do: @email_regex

  @doc "纯数字的正则表达式"
  def pure_number_regex, do: @pure_number_regex

  @doc "整数的正则表达式"
  def integer_regex, do: @integer_regex

  @doc "文字正则"
  def words_regex, do: @words_regex

  @doc "只匹配文字，下划线和中划线, 数字"
  def name_regex_match?(str) do
    String.replace(str, @words_regex, "") |> String.length() == 0
  end

  @doc "半角和全角得空格"
  def space_strings, do: [" ", "　"]

  @doc "匹配URL的正则表达式"
  def match_url_regex, do: Regex.compile!("^#{@scan_url_regex |> Enum.join()}")

  @doc """
  扫描出URL的正则表达式
  ```
  eg:
  * https://msdn.microsoft.com/en-us/library/ff650303.aspx#paght000001_commonregularexpressions
  * http://stackoverflow.com/questions/1323283/how-to-match-url-in-c
  ```
  """
  def scan_url_regex, do: Regex.compile!(@scan_url_regex |> Enum.join())

  @doc "web url format"
  def website_url_regex, do: @website_url_regex

  @doc "手机号码的正则表达式，按照国家归属"
  def mobile_number_formats, do: @mobile_number_formats

  def normalize_mobile_number!(region_key, mobile_number) do
    if mobile_number_format = @mobile_number_formats |> Fulib.get(region_key) do
      length_require = mobile_number_format |> Fulib.get(:length)

      mobile_number =
        mobile_number
        |> Fulib.to_s()
        |> String.trim()

      length = String.length(mobile_number)

      cond do
        length > length_require -> String.slice(mobile_number, -length_require, length_require)
        true -> mobile_number
      end
    else
      mobile_number
    end
  end

  def mobile_number_match?(nil, _mobile_number), do: false
  def mobile_number_match?(_region_key, nil), do: false

  def mobile_number_match?(region_key, mobile_number) do
    if mobile_number_format = @mobile_number_formats |> Fulib.get(region_key) do
      Regex.match?(mobile_number_format[:regex], mobile_number)
    else
      false
    end
  end
end
