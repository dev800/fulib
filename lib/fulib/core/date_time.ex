defmodule Fulib.DateTime do
  @utc_timezone "Etc/UTC"
  @default_timezone Application.get_env(:fulib, :default_timezone) || "Etc/UTC"
  # @default_utc_offset Application.get_env(:fulib, :default_utc_offset) || 28_800

  def now(timezone \\ @default_timezone) do
    Timex.Timezone.convert(Timex.now(), timezone)
  end

  def utc_now do
    now("Etc/UTC")
  end

  def naive_now(timezone \\ @default_timezone) do
    Timex.now()
    |> Timex.shift(
      seconds:
        Timex.Timezone.diff(Timex.Timezone.get(@utc_timezone), Timex.Timezone.get(timezone))
    )
    |> Timex.to_naive_datetime()
  end

  @doc """
  时间日期的格式化话
  # opts
  ```
  * timezone
    - :original

  * :locale

  * format
    - :gmt
    - :long         eg: 2017-03-10 09:38:30 默认
    - :utc_strftime eg: 2017-03-10T01:38:12Z
    - :short        eg: 2017-03-10 09:39
    - :utc_iso8601  eg: 2017-03-10T01:46:27.860643+00:00
    - :date         eg: 2017-03-10
    - :date_short   eg: 2017-3-10
    - :diff
    _ :human

  * overflow_format
    - :date
  ```
  """
  def format!(datetime), do: format!(datetime, [])

  def format!(nil, _opts), do: nil

  def format!(datetime, opts) when is_list(opts) do
    format!(datetime, opts |> Fulib.get(:format, :long) |> Fulib.to_atom(), opts)
  end

  def format!(datetime, format) when is_atom(format), do: format!(datetime, format, [])

  def format!(nil, _format, _opts), do: nil

  def format!(datetime, format, opts) do
    timezone = opts[:timezone] || @default_timezone

    datetime =
      case timezone do
        :original -> get_zone_time(datetime, timezone)
        _ -> Timex.Timezone.convert(datetime, timezone)
      end

    _format!(datetime, format, opts)
  end

  defp _format!(datetime, :gmt, _opts) do
    datetime |> Timex.format!("%a, %d %b %Y %H:%M:%S", :strftime)
  end

  defp _format!(datetime, :seconds, _opts) do
    "#{Timex.format!(datetime, "%Y%m%d%H%M%S", :strftime)}"
  end

  defp _format!(datetime, :date_short, _opts) do
    "#{Timex.format!(datetime, "%Y-%-m-%-d", :strftime)}"
  end

  defp _format!(datetime, :date, _opts) do
    "#{Timex.format!(datetime, "%Y-%m-%d", :strftime)}"
  end

  defp _format!(datetime, :utc_iso8601, _opts) do
    Timex.format!(Timex.Timezone.convert(datetime, @utc_timezone), "%FT%T%:z", :strftime)
  end

  defp _format!(datetime, :tight, _opts) do
    if datetime.year == Timex.now().year do
      "#{Timex.format!(datetime, "%-m-%-d %H:%M", :strftime)}"
    else
      "#{Timex.format!(datetime, "%-y-%-m-%-d %H:%M", :strftime)}"
    end
  end

  defp _format!(datetime, :short, _opts) do
    "#{Timex.format!(datetime, "%Y-%m-%d %H:%M", :strftime)}"
  end

  defp _format!(datetime, :utc_strftime, _opts) do
    "#{Timex.format!(Timex.Timezone.convert(datetime, @utc_timezone), "%FT%TZ", :strftime)}"
  end

  defp _format!(datetime, :long, _opts) do
    "#{Timex.format!(datetime, "%Y-%m-%d %H:%M:%S", :strftime)}"
  end

  defp _format!(datetime, :long_zone, _opts) do
    "#{Timex.format!(datetime, "%Y-%m-%d %H:%M:%S %:z", :strftime)}"
  end

  defp _format!(datetime, :timestamp, _opts) do
    datetime |> Timex.to_unix()
  end

  defp _format!(datetime, :timestamp_ms, _opts) do
    {microsecond, 6} = datetime.microsecond
    millisecond = (microsecond / 1_000) |> Fulib.to_i()
    (datetime |> Timex.to_unix()) * 1_000 + millisecond
  end

  defp _format!(datetime, :timestamp_μs, _opts) do
    {microsecond, 6} = datetime.microsecond
    (datetime |> Timex.to_unix()) * 1_000_000 + microsecond
  end

  defp _format!(datetime, :diff, opts) do
    timezone = opts[:timezone] || @default_timezone
    locale = opts[:locale] || Fulib.Translator.current_locale()
    format_diff!(datetime, timezone: timezone, locale: locale)
  end

  defp _format!(datetime, :human, opts) do
    timezone = opts[:timezone] || @default_timezone
    locale = opts[:locale] || Fulib.Translator.current_locale()
    overflow_format = Fulib.get(opts, :overflow_format, :default)
    overflow_format = if overflow_format == :human, do: :default, else: overflow_format

    format_human!(
      datetime,
      timezone: timezone,
      locale: locale,
      overflow_format: overflow_format
    )
  end

  defp _format!(datetime, _, _opts) do
    "#{Timex.format!(datetime, "%Y-%m-%d %H:%M:%S", :strftime)}"
  end

  def get_zone_time(datetime, timezone \\ @default_timezone) do
    datetime |> Timex.Timezone.convert(timezone)
  end

  def gt_or_eq?(a, b) do
    gt?(a, b) or eq?(a, b)
  end

  def gt?(a, b) do
    Timex.after?(a, b)
  end

  def lt_or_eq?(a, b) do
    lt?(a, b) or eq?(a, b)
  end

  def lt?(a, b) do
    Timex.before?(a, b)
  end

  def eq?(a, b) do
    Timex.equal?(a, b)
  end

  def format_diff!(datetime, opts \\ []) do
    timezone = opts |> Fulib.get(:timezone, @default_timezone)
    locale = opts |> Fulib.get(:locale, Fulib.Translator.current_locale())

    now =
      case timezone do
        :original ->
          get_zone_time(Timex.now(), timezone)

        _ ->
          Timex.Timezone.convert(Timex.now(), timezone)
      end

    diff_seconds = Timex.diff(now, datetime, :seconds)

    cond do
      diff_seconds in 0..60 ->
        Fulib.Translator.with_locale(locale, fn ->
          Fulib.Translator.dgettext(
            "datetime",
            "%{diff_seconds} seconds ago",
            diff_minutes: diff_seconds
          )
        end)

      # 1分钟 -> 1小时
      diff_seconds in 60..3600 ->
        Fulib.Translator.with_locale(locale, fn ->
          Fulib.Translator.dgettext(
            "datetime",
            "%{diff_minutes} minutes ago",
            diff_minutes: Fulib.to_i(diff_seconds / 60)
          )
        end)

      # 1小时 -> 24小时
      diff_seconds in 3600..86400 ->
        Fulib.Translator.with_locale(locale, fn ->
          Fulib.Translator.dgettext(
            "datetime",
            "%{diff_hours} hours ago",
            diff_hours: Fulib.to_i(diff_seconds / 3600)
          )
        end)

      # 24小时 -> 48小时
      diff_seconds in 86400..172_800 ->
        Fulib.Translator.with_locale(locale, fn ->
          Fulib.Translator.dgettext(
            "datetime",
            "1 days ago",
            diff_days: Fulib.to_i(diff_seconds / 86400)
          )
        end)

      # 48小时 -> 72小时
      diff_seconds in 172_800..259_200 ->
        Fulib.Translator.with_locale(locale, fn ->
          Fulib.Translator.dgettext(
            "datetime",
            "2 days ago",
            diff_days: Fulib.to_i(diff_seconds / 86400)
          )
        end)

      # 3天前
      diff_seconds >= 259_200 ->
        Fulib.Translator.with_locale(locale, fn ->
          Fulib.Translator.dgettext(
            "datetime",
            "%{diff_days} days ago",
            diff_days: Fulib.to_i(diff_seconds / 86400)
          )
        end)

      -diff_seconds in 0..60 ->
        Fulib.Translator.with_locale(locale, fn ->
          Fulib.Translator.dgettext(
            "datetime",
            "%{diff_seconds} seconds after",
            diff_minutes: diff_seconds
          )
        end)

      # 1分钟 -> 1小时
      -diff_seconds in 60..3600 ->
        Fulib.Translator.with_locale(locale, fn ->
          Fulib.Translator.dgettext(
            "datetime",
            "%{diff_minutes} minutes after",
            diff_minutes: Fulib.to_i(-diff_seconds / 60)
          )
        end)

      # 1小时 -> 24小时
      -diff_seconds in 3600..86400 ->
        Fulib.Translator.with_locale(locale, fn ->
          Fulib.Translator.dgettext(
            "datetime",
            "%{diff_hours} hours after",
            diff_hours: Fulib.to_i(-diff_seconds / 3600)
          )
        end)

      # 24小时 -> 48小时
      -diff_seconds in 86400..172_800 ->
        Fulib.Translator.with_locale(locale, fn ->
          Fulib.Translator.dgettext(
            "datetime",
            "1 days after",
            diff_days: Fulib.to_i(-diff_seconds / 86400)
          )
        end)

      # 48小时 -> 72小时
      -diff_seconds in 172_800..259_200 ->
        Fulib.Translator.with_locale(locale, fn ->
          Fulib.Translator.dgettext(
            "datetime",
            "2 days after",
            diff_days: Fulib.to_i(-diff_seconds / 86400)
          )
        end)

      # 3天前
      -diff_seconds >= 259_200 ->
        Fulib.Translator.with_locale(locale, fn ->
          Fulib.Translator.dgettext(
            "datetime",
            "%{diff_days} days after",
            diff_days: Fulib.to_i(-diff_seconds / 86400)
          )
        end)
    end
  end

  def format_human!(datetime, opts \\ [])
  def format_human!(nil, _opts), do: nil

  def format_human!(datetime, opts) do
    timezone = opts |> Fulib.get(:timezone, @default_timezone)
    locale = opts |> Fulib.get(:locale, Fulib.Translator.current_locale())
    overflow_format = opts |> Fulib.get(:overflow_format, :default)

    original_datetime = datetime

    now =
      case timezone do
        :original ->
          get_zone_time(Timex.now(), timezone)

        _ ->
          Timex.Timezone.convert(Timex.now(), timezone)
      end

    datetime =
      case timezone do
        :original ->
          get_zone_time(datetime, timezone)

        _ ->
          Timex.Timezone.convert(datetime, timezone)
      end

    # 今天开始
    today_beginning = Timex.beginning_of_day(now)
    # 昨天开始
    yesterday_beginning = Timex.shift(today_beginning, seconds: -86400)
    # 前天开始
    the_day_before_yesterday_beginning = Timex.shift(today_beginning, seconds: -172_800)
    # 明天开始
    tomorrow_beginning = Timex.shift(today_beginning, seconds: 86400)
    # 前天开始
    the_day_after_tomorrow_beginning = Timex.shift(today_beginning, seconds: 172_800)

    time_string = Timex.format!(datetime, "%H:%M", :strftime)

    cond do
      gt_or_eq?(datetime, today_beginning) && lt?(datetime, tomorrow_beginning) ->
        # 今天
        Fulib.Translator.with_locale(locale, fn ->
          Fulib.Translator.dgettext("datetime", "Today %{time}", time: time_string)
        end)

      gt_or_eq?(datetime, yesterday_beginning) && lt?(datetime, today_beginning) ->
        # 昨天
        Fulib.Translator.with_locale(locale, fn ->
          Fulib.Translator.dgettext("datetime", "Yesterday %{time}", time: time_string)
        end)

      gt_or_eq?(datetime, the_day_before_yesterday_beginning) &&
          lt?(datetime, yesterday_beginning) ->
        # 前天
        Fulib.Translator.with_locale(locale, fn ->
          Fulib.Translator.dgettext(
            "datetime",
            "The day before yesterday %{time}",
            time: time_string
          )
        end)

      gt_or_eq?(datetime, tomorrow_beginning) && lt?(datetime, the_day_after_tomorrow_beginning) ->
        # 明天
        Fulib.Translator.with_locale(locale, fn ->
          Fulib.Translator.dgettext("datetime", "Tomorrow %{time}", time: time_string)
        end)

      gt_or_eq?(datetime, the_day_after_tomorrow_beginning) &&
          lt?(datetime, Timex.beginning_of_day(Timex.shift(today_beginning, seconds: 259_200))) ->
        # 后天
        Fulib.Translator.with_locale(locale, fn ->
          Fulib.Translator.dgettext(
            "datetime",
            "The day after tomorrow %{time}",
            time: time_string
          )
        end)

      true ->
        format!(original_datetime, timezone: timezone, locale: locale, format: overflow_format)
    end
  end

  @doc """
  得到某一时间范围

  ## Examples

  ```
  iex> range(:today)
  {~N[2018-07-25 00:00:00], ~N[2018-07-26 00:00:00]}

  iex> range(4)
  {~N[2018-07-22 00:00:00], ~N[2018-07-26 00:00:00]}

  iex> range(nil)
  {nil, nil}
  ```
  """
  @spec range(integer, integer) :: tuple
  def range(begin_shift, end_shift) do
    {_get_date(begin_shift), _get_date(end_shift)}
  end

  @spec range(atom | nil) :: tuple
  def range(nil), do: {nil, nil}

  def range(date_range) do
    {
      _get_date(date_range, :begin),
      _get_date(date_range, :end)
    }
  end

  @date_shift_map %{
    begin: %{today: 0, yesterday: -1, three: -2},
    end: %{today: 1, yesterday: 0, three: 1}
  }

  defp _get_date(nil), do: nil

  defp _get_date(days_shift) do
    Fulib.naive_now() |> Timex.beginning_of_day() |> Timex.shift(days: days_shift)
  end

  defp _get_date(date_range, :begin) when is_number(date_range) do
    _get_date(date_range * -1 + 1)
  end

  defp _get_date(date_range, :end) when is_number(date_range) do
    _get_date(1)
  end

  defp _get_date(date_range, point) do
    _get_date(@date_shift_map[point][date_range])
  end
end
