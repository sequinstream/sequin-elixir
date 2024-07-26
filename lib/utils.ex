defmodule Sequin.Utils do
  def parse_datetime(nil), do: nil

  def parse_datetime(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _offset} -> datetime
      _ -> nil
    end
  end
end
