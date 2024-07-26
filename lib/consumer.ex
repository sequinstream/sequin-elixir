defmodule Sequin.Consumer do
  alias Sequin.Utils

  defstruct [
    :ack_wait_ms,
    :filter_key_pattern,
    :id,
    :inserted_at,
    :kind,
    :max_ack_pending,
    :max_deliver,
    :max_waiting,
    :name,
    :stream_id,
    :updated_at,
    :http_endpoint_id,
    :status
  ]

  def decode(attrs) when is_map(attrs) do
    attrs
    |> Map.new(fn {k, v} -> {String.to_existing_atom(k), v} end)
    |> Map.update(:inserted_at, nil, &Utils.parse_datetime/1)
    |> Map.update(:updated_at, nil, &Utils.parse_datetime/1)
    |> then(&struct(__MODULE__, &1))
  end
end
