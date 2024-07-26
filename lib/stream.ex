defmodule Sequin.Stream do
  alias Sequin.Utils

  @type t :: %{
          id: String.t(),
          name: String.t(),
          account_id: String.t(),
          stats: map(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  defstruct [
    :id,
    :name,
    :account_id,
    :stats,
    :inserted_at,
    :updated_at
  ]

  def decode(data) do
    %__MODULE__{
      id: data["id"],
      name: data["name"],
      account_id: data["account_id"],
      stats: data["stats"],
      inserted_at: Utils.parse_datetime(data["inserted_at"]),
      updated_at: Utils.parse_datetime(data["updated_at"])
    }
  end
end
