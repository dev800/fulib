defmodule Fulib.Timex do
  def beginning_of_second(datetime) do
    %DateTime{datetime | microsecond: {0, 6}}
  end

  def beginning_of_minute(datetime) do
    %DateTime{datetime | second: 0, microsecond: {0, 6}}
  end

  def beginning_of_hour(datetime) do
    %DateTime{datetime | minute: 0, second: 0, microsecond: {0, 6}}
  end

  # 日
  defdelegate beginning_of_day(datetime), to: Timex
  # 星期
  defdelegate beginning_of_week(date, weekstart \\ :mon), to: Timex
  # 月
  defdelegate beginning_of_month(datetime), to: Timex
  # 月
  defdelegate beginning_of_month(year, month), to: Timex
  # 季度
  defdelegate beginning_of_quarter(datetime), to: Timex
  # 年
  defdelegate beginning_of_year(year), to: Timex
end
