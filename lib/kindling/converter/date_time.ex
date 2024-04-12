defmodule Kindling.Converter.DateTime do
  @moduledoc """
  Handles dates and datetimes in FHIR's format. Dates may be in ISO8601 format, or may be in a truncated
  form that indicates only certain parts of a date (e.g. year, or year+month, etc). DateTimes work
  similarly.
  """

  defstruct year: "",
            month: "",
            day: "",
            hour: "",
            minute: "",
            second: "",
            zone: ""

  @doc """
  Parse a string containing a FHIR-style datetime. Return `{:ok, DateTime.t(), integer()}` or a parse
  error.
  """
  @spec parse(binary()) ::
          {:error,
           :incompatible_calendars
           | :invalid_date
           | :invalid_format
           | :invalid_time
           | :missing_offset}
          | {:ok, DateTime.t(), integer()}
  def parse(value) do
    value
    |> String.codepoints()
    |> do_year(%__MODULE__{})
    |> set_defaults()
    |> to_iso_string()
    |> DateTime.from_iso8601()
  end

  @doc false
  def to_iso_string(%{
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: second,
        zone: zone
      }) do
    "#{year}-#{month}-#{day}T#{hour}:#{minute}:#{second}#{zone}"
  end

  @doc false
  def set_defaults(%{
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: second,
        zone: zone
      }) do
    %__MODULE__{
      year: format(year, "0000"),
      month: format(month, "01"),
      day: format(day, "01"),
      hour: format(hour, "00"),
      minute: format(minute, "00"),
      second: format(second, "00"),
      zone: if(zone == "", do: "Z", else: zone)
    }
  end

  defp format("", default), do: default
  defp format(string, default), do: String.pad_leading(string, String.length(default), "0")

  @doc false
  def do_year([], data), do: data
  def do_year(["-" | tail], data), do: do_month(tail, data)
  def do_year([hd | tail], %{year: year} = data), do: do_year(tail, %{data | year: year <> hd})

  @doc false
  def do_month([], data), do: data
  def do_month(["-" | tail], data), do: do_day(tail, data)

  def do_month([hd | tail], %{month: month} = data),
    do: do_month(tail, %{data | month: month <> hd})

  @doc false
  def do_day([], data), do: data
  def do_day(["T" | tail], data), do: do_hour(tail, data)
  def do_day([hd | tail], %{day: day} = data), do: do_day(tail, %{data | day: day <> hd})

  @doc false
  def do_hour([], data), do: data
  def do_hour([":" | tail], data), do: do_minute(tail, data)
  def do_hour([hd | tail], %{hour: hour} = data), do: do_hour(tail, %{data | hour: hour <> hd})

  @doc false
  def do_minute([], data), do: data
  def do_minute([":" | tail], data), do: do_second(tail, data)

  def do_minute([hd | tail], %{minute: minute} = data),
    do: do_minute(tail, %{data | minute: minute <> hd})

  @doc false
  def do_second([], data), do: data
  def do_second([c | tail], data) when c in ["+", "-", "Z"], do: do_zone(tail, data)

  def do_second([hd | tail], %{second: second} = data),
    do: do_second(tail, %{data | second: second <> hd})

  @doc false
  def do_zone([], data), do: data
  def do_zone([hd | tail], %{zone: zone} = data), do: do_zone(tail, %{data | zone: zone <> hd})
end
