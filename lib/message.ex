defmodule Sequin.Message do
  alias Sequin.Utils

  @type t :: %{
          key: String.t(),
          stream_id: String.t(),
          data: String.t(),
          seq: integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  defstruct [
    :key,
    :stream_id,
    :data,
    :seq,
    :inserted_at,
    :updated_at
  ]

  def decode(message) do
    %{
      "key" => key,
      "stream_id" => stream_id,
      "data" => data,
      "seq" => seq,
      "inserted_at" => inserted_at,
      "updated_at" => updated_at
    } = message

    %__MODULE__{
      key: key,
      stream_id: stream_id,
      data: data,
      seq: seq,
      inserted_at: Utils.parse_datetime(inserted_at),
      updated_at: Utils.parse_datetime(updated_at)
    }
  end
end
