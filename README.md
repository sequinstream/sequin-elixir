# Sequin

A lightweight Elixir SDK for sending, receiving, and acknowledging messages in [Sequin streams](https://github.com/sequinstream/sequin).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `sequin` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sequin, "~> 0.1.0"}
  ]
end
```

## Configuration

To use Sequin in your application, you'll need to configure it in your `config.exs` file. Add the following configuration:

```elixir
# config/config.exs

config :sequin,
  base_url: System.get_env("SEQUIN_URL") || "http://localhost:7673"
```

By default, the Client is initialized using Sequin's default host and port in local development: `http://localhost:7673`

## Usage

You'll predominantly use `Sequin` to send, receive, and acknowledge [messages](https://github.com/sequinstream/sequin?tab=readme-ov-file#messages) in Sequin streams:

```elixir
# Define your stream and consumer
stream = "your-stream-name"
consumer = "your-consumer-name"

# Send a message
case Sequin.send_message(stream, "test.1", "Hello, Sequin!") do
  {:ok, %{published: 1}} ->
    IO.puts("Message sent successfully")

  {:error, error} ->
    IO.puts("Error sending message: #{Exception.message(error)}")
end

# Receive a message
with {:ok, %{message: message, ack_id: ack_id}} <- Sequin.receive_message(stream, consumer),
     :ok <- YourApp.process_message(message),
     :ok <- Sequin.ack_message(stream, consumer, ack_id) do
  IO.puts("Received and acked message: #{inspect(message)}")
else
  {:ok, nil} ->
    IO.puts("No messages available")

  {:error, error} ->
    IO.puts("Error: #{Exception.message(error)}")
end
```

### `send_message/3`

[Send](https://github.com/sequinstream/sequin?tab=readme-ov-file#sending-messages) a message to a stream:

```elixir
{:ok, %{published: count}} = Sequin.send_message(stream_id_or_name, key, data)
```

#### Parameters

`send_message/3` accepts three arguments:

- `stream_id_or_name` (string): Either the name or id of the stream.
- `key` (string): The key for the message.
- `data` (string or map): The data payload for the message. Can be either a map or a string (maps will be JSON encoded).

#### Returns

`send_message/3` will return a status tuple:

**Success**

```elixir
{:ok, %{published: 1}}
```

**Error**

```elixir
{:error, %{status: 404, summary: "stream not found"}}
```

#### Example

```elixir
case Sequin.send_message("my_stream", "greeting.1", "Hello, Sequin!") do
  {:ok, %{published: _count}} ->
    IO.puts("Message sent successfully")

  {:error, error} ->
    IO.puts("Error sending message: #{Exception.message(error)}")
end
```

### `send_messages/2`

Send a batch of messages (max 1,000):

```elixir
{:ok, %{published: _count}} = Sequin.send_messages(stream_id_or_name, messages)
```

#### Parameters

`send_messages/2` accepts two arguments:

- `stream_id_or_name` (string): Either the name or id of the stream.
- `messages` (list): A list of message maps:

```elixir
[
  %{key: "message_key_1", data: "data_payload_1"},
  %{key: "message_key_2", data: "data_payload_2"},
  # ...
]
```

#### Returns

`send_messages/2` will return a tuple:

> [!IMPORTANT] > `send_messages/2` is all or nothing. Either all the messages are successfully published, or none of the messages are published.

**Success**

```elixir
{:ok, %{published: 42}}
```

**Error**

```elixir
{:error, %{status: 404, summary: "Stream not found"}}
```

#### Example

```elixir
messages = [
  %{key: "test.1", data: "Hello, Sequin!"},
  %{key: "test.2", data: "Greetings from Sequin!"}
]

case Sequin.send_messages("my_stream", messages) do
  {:ok, %{published: _count}} ->
    IO.puts("Messages sent successfully")

  {:error, error} ->
    IO.puts("Error sending messages: #{Exception.message(error)}")
end
```

### `receive_message/2`

To pull a single message off the stream using a Sequin consumer, you'll use the `receive_message/2` function:

```elixir
{:ok, message} = Sequin.receive_message(stream_id_or_name, consumer_id_or_name)
```

#### Parameters

`receive_message/2` accepts two arguments:

- `stream_id_or_name` (string): Either the name or id of the stream.
- `consumer_id_or_name` (string): Either the name or id of the consumer.

#### Returns

`receive_message/2` will return a tuple:

**No messages available**

```elixir
{:ok, nil}
```

**Message**

```elixir
{:ok, %{
  message: %Sequin.Message{
    key: "test.1",
    stream_id: "def45b2d-ae3f-46a4-b57b-54cdc1cecc6d",
    data: "Hello, Sequin!",
    seq: 1,
    inserted_at: "2024-07-23T00:31:55.668060Z",
    updated_at: "2024-07-23T00:31:55.668060Z"
  },
  ack_id: "07240856-96cb-4305-9b2f-620f4b1528a4"
}}
```

**Error**

```elixir
{:error, %{status: 404, summary: "Consumer not found."}}
```

#### Example

```elixir
case Sequin.receive_message("my_stream", "my_consumer") do
  {:ok, nil} ->
    IO.puts("No messages available")

  {:ok, %{message: message, ack_id: ack_id}} ->
    IO.puts("Message received successfully: #{inspect(message)}")

  {:error, error} ->
    IO.puts("Error receiving message: #{Exception.message(error)}")
end
```

### `receive_messages/3`

You can pull a batch of messages for your consumer using `receive_messages/3`. It pulls a batch of `10` messages by default:

```elixir
{:ok, messages} = Sequin.receive_messages(stream_id_or_name, consumer_id_or_name, options \\ [])
```

#### Parameters

`receive_messages/3` accepts three arguments:

- `stream_id_or_name` (string): Either the name or id of the stream.
- `consumer_id_or_name` (string): Either the name or id of the consumer.
- `options` (keyword list, optional): A keyword list that defines optional parameters:
  - `:batch_size` (integer): The number of messages to request. Default is 10, max of 1,000.

#### Returns

`receive_messages/3` will return a tuple:

**No messages available**

```elixir
{:ok, []}
```

**Messages**

```elixir
{:ok, [
  %{
    message: %Sequin.Message{
      key: "test.1",
      stream_id: "def45b2d-ae3f-46a4-b57b-54cdc1cecc6d",
      data: "Hello, Sequin!",
      seq: 1,
      inserted_at: "2024-07-23T00:31:55.668060Z",
      updated_at: "2024-07-23T00:31:55.668060Z"
    },
    ack_id: "07240856-96cb-4305-9b2f-620f4b1528a4"
  },
  # ...
]}
```

**Error**

```elixir
{:error, %{status: 404, summary: "Consumer not found."}}
```

#### Example

```elixir
case Sequin.receive_messages("my_stream", "my_consumer", batch_size: 100) do
  {:ok, []} ->
    IO.puts("No messages available")

  {:ok, messages} ->
    IO.puts("Messages received successfully: #{inspect(messages)}")

  {:error, error} ->
    IO.puts("Error receiving messages: #{Exception.message(error)}")
end
```

### `ack_message/3`

After processing a message, you can [acknowledge](https://github.com/sequinstream/sequin?tab=readme-ov-file#acking-messages) it using `ack_message/3`:

```elixir
:ok = Sequin.ack_message(stream_id_or_name, consumer_id_or_name, ack_id)
```

#### Parameters

`ack_message/3` accepts three arguments:

- `stream_id_or_name` (string): Either the name or id of the stream.
- `consumer_id_or_name` (string): Either the name or id of the consumer.
- `ack_id` (string): The `ack_id` for the message you want to ack.

#### Returns

`ack_message/3` will return `:ok` if successful and `{:error, error}` if not.

**Success**

```elixir
:ok
```

**Error**

```elixir
{:error, %{status: 400, summary: "Invalid ack_id."}}
```

#### Example

```elixir
case Sequin.ack_message("my_stream", "my_consumer", "07240856-96cb-4305-9b2f-620f4b1528a4") do
  :ok ->
    IO.puts("Message acknowledged successfully")

  {:error, error} ->
    IO.puts("Error acknowledging message: #{Exception.message(error)}")
end
```

### `ack_messages/3`

You can also [acknowledge](https://github.com/sequinstream/sequin?tab=readme-ov-file#acking-messages) a batch of messages using `ack_messages/3`:

```elixir
:ok = Sequin.ack_messages(stream_id_or_name, consumer_id_or_name, ack_ids)
```

#### Parameters

`ack_messages/3` accepts three arguments:

- `stream_id_or_name` (string): Either the name or id of the stream.
- `consumer_id_or_name` (string): Either the name or id of the consumer.
- `ack_ids` (list): A list of `ack_id` strings for the messages you want to ack.

#### Returns

`ack_messages/3` will return `:ok` if successful and `{:error, error}` if not.

> [!IMPORTANT] > `ack_messages/3` is all or nothing. Either all the messages are successfully acknowledged, or none of the messages are acknowledged.

**Success**

```elixir
:ok
```

**Error**

```elixir
{:error, %{status: 400, summary: "Invalid ack_id."}}
```

#### Example

```elixir
ack_ids = ["07240856-96cb-4305-9b2f-620f4b1528a4", "522c69a1-0bbe-49ec-9d0d-e39b40d483f8"]

case Sequin.ack_messages("my_stream", "my_consumer", ack_ids) do
  :ok ->
    IO.puts("Messages acknowledged successfully")

  {:error, error} ->
    IO.puts("Error acknowledging messages: #{Exception.message(error)}")
end
```

### `nack_message/3`

Or, you can [`nack`](https://github.com/sequinstream/sequin?tab=readme-ov-file#nacking-messages) a message using `nack_message/3`:

```elixir
:ok = Sequin.nack_message(stream_id_or_name, consumer_id_or_name, ack_id)
```

#### Parameters

`nack_message/3` accepts three arguments:

- `stream_id_or_name` (string): Either the name or id of the stream.
- `consumer_id_or_name` (string): Either the name or id of the consumer.
- `ack_id` (string): The `ack_id` for the message to **not** acknowledge.

#### Returns

`nack_message/3` will return `:ok` if successful and `{:error, error}` if not.

**Success**

```elixir
:ok
```

**Error**

```elixir
{:error, %{status: 400, summary: "Invalid ack_id"}}
```

#### Example

```elixir
case Sequin.nack_message("my_stream", "my_consumer", "07240856-96cb-4305-9b2f-620f4b1528a4") do
  :ok ->
    IO.puts("Message nacked successfully")
  {:error, error} ->
    IO.puts("Error nacking message: #{Exception.message(error)}")
end
```

### `nack_messages/3`

Or, you can [`nack`](https://github.com/sequinstream/sequin?tab=readme-ov-file#nacking-messages) a batch of messages using `nack_messages/3`:

```elixir
:ok = Sequin.nack_messages(stream_id_or_name, consumer_id_or_name, ack_ids)
```

#### Parameters

`nack_messages/3` accepts three arguments:

- `stream_id_or_name` (string): Either the name or id of the stream.
- `consumer_id_or_name` (string): Either the name or id of the consumer.
- `ack_ids` (list): A list of `ack_id` strings for the messages to **not** acknowledge.

#### Returns

`nack_messages/3` will return a tuple:

> [!IMPORTANT] > `nack_messages/3` is all or nothing. Either all the messages are successfully nacked, or none of the messages are nacked.

**Success**

```elixir
:ok
```

**Error**

```elixir
{:error, %{status: 400, summary: "Invalid ack_id"}}
```

#### Example

```elixir
ack_ids = ["07240856-96cb-4305-9b2f-620f4b1528a4", "522c69a1-0bbe-49ec-9d0d-e39b40d483f8"]

case Sequin.nack_messages("my_stream", "my_consumer", ack_ids) do
  :ok ->
    IO.puts("Messages nacked successfully")

  {:error, error} ->
    IO.puts("Error nacking messages: #{Exception.message(error)}")
end
```

### `create_stream/2`

Creating streams can be helpful in automated testing. You can create a new stream using `create_stream/2`:

```elixir
{:ok, result} = Sequin.create_stream(stream_name, options \\ [])
```

#### Parameters

`create_stream/2` accepts two parameters:

- `name` (string): The name of the stream you want to create.
- `options` (keyword list, optional): A keyword list that defines optional parameters:
  - `:one_message_per_key` (boolean)
  - `:process_unmodified` (boolean)
  - `:max_storage_gb` (integer)
  - `:retain_up_to` (integer)
  - `:retain_at_least` (integer)

#### Returns

`create_stream/2` will return a tuple:

**Success**

```elixir
{:ok,
  %Sequin.Stream{
    id: "197a3ee8-8ddd-4ddd-8456-5d0b78a72784",
    name: "my_stream",
    account_id: "8b930c30-2334-4339-b7ba-f250b7be223e",
    stats: %{
      message_count: 0,
      consumer_count: 0,
      storage_size: 163840
    },
    inserted_at: "2024-07-24T20:02:46Z",
    updated_at: "2024-07-24T20:02:46Z"
}}
```

**Error**

```elixir
{:error, %{status: 422, summary: "Validation failed: duplicate name"}}
```

#### Example

```elixir
case Sequin.create_stream("my_stream") do
  {:ok, stream} ->
    IO.puts("Stream created successfully: #{inspect(stream)}")

  {:error, error} ->
    IO.puts("Error creating stream: #{Exception.message(error)}")
end
```

### `delete_stream/1`

Deleting streams can be helpful in automated testing. You can delete a stream using `delete_stream/1`:

```elixir
{:ok, result} = Sequin.delete_stream(stream_id_or_name)
```

#### Parameters

`delete_stream/1` accepts one parameter:

- `stream_id_or_name` (string): The id or name of the stream you want to delete.

#### Returns

`delete_stream/1` will return a tuple:

**Successful delete**

```elixir
{:ok, %{id: "197a3ee8-8ddd-4ddd-8456-5d0b78a72784", deleted: true}}
```

**Error**

```elixir
{:error, %{status: 404, summary: "Not found: No `stream` found matching the provided ID or name"}}
```

#### Example

```elixir
case Sequin.delete_stream("my_stream") do
  {:ok, result} ->
    IO.puts("Stream deleted successfully: #{inspect(result)}")

  {:error, error} ->
    IO.puts("Error deleting stream: #{Exception.message(error)}")
end
```

### `create_consumer/4`

Creating [consumers](https://github.com/sequinstream/sequin?tab=readme-ov-file#consumers-1) can be helpful in automated testing. You can create a new consumer using `create_consumer/4`:

```elixir
Sequin.create_consumer(stream_id_or_name, consumer_name, consumer_filter, options \\ [])
```

#### Parameters

`create_consumer/4` accepts four parameters:

- `stream_id_or_name` (string): The id or name of the stream you want to attach the consumer to.
- `name` (string): The name of the consumer you want to create.
- `filter` (string): The filter pattern the consumer will use to pull messages off the stream.
- `options` (keyword list, optional): A keyword list that defines optional parameters:
  - `:ack_wait_ms` (integer): Acknowledgement wait time in milliseconds
  - `:max_ack_pending` (integer): Maximum number of pending acknowledgements
  - `:max_deliver` (integer): Maximum number of delivery attempts

#### Returns

`create_consumer/4` will return a tuple:

**Success**

```elixir
{:ok,
  %Sequin.Consumer{
    ack_wait_ms: 30000,
    filter_key_pattern: "test.>",
    id: "67df6362-ba21-4ddc-8601-55d404bacaeb",
    inserted_at: "2024-07-24T20:12:20Z",
    kind: "pull",
    max_ack_pending: 10000,
    max_deliver: nil,
    max_waiting: 20,
    name: "my_consumer",
    stream_id: "15b1f003-3a47-4371-8331-6437cb48477e",
    updated_at: "2024-07-24T20:12:20Z",
    http_endpoint_id: nil,
    status: "active"
  }
}
```

**Error**

```elixir
{:error, %{status: 422, summary: "Validation failed: duplicate name"}}
```

#### Example

```elixir
case Sequin.create_consumer("my_stream", "my_consumer", "test.>") do
  {:ok, %Sequin.Consumer{} = consumer} ->
    IO.puts("Consumer created successfully: #{inspect(consumer)}")

  {:error, error} ->
    IO.puts("Error creating consumer: #{Exception.message(error)}")
end
```

### `delete_consumer/2`

Deleting consumers can be helpful in automated testing. You can delete a consumer using `delete_consumer/2`:

```elixir
{:ok, result} = Sequin.delete_consumer(stream_id_or_name, consumer_id_or_name)
```

#### Parameters

`delete_consumer/2` accepts two parameters:

- `stream_id_or_name` (string): The id or name of the stream associated with the consumer you want to delete.
- `consumer_id_or_name` (string): The id or name of the consumer you want to delete.

#### Returns

`delete_consumer/2` will return a tuple:

**Successful delete**

```elixir
{:ok, %{id: "197a3ee8-8ddd-4ddd-8456-5d0b78a72784", deleted: true}}
```

**Error**

```elixir
{:error, %{status: 404, summary: "Not found: No `consumer` found matching the provided ID or name"}}
```

#### Example

```elixir
case Sequin.delete_consumer("my_stream", "my_consumer") do
  {:ok, result} ->
    IO.puts("Consumer deleted successfully: #{inspect(result)}")

  {:error, error} ->
    IO.puts("Error deleting consumer: #{Exception.message(error)}")
end
```

## Testing

To adequately test Sequin, we recommend creating temporary streams and consumers in addition to testing sending and receiving messages. Here's an example using ExUnit:

```elixir
defmodule SequinTest do
  use ExUnit.Case
  alias Sequin

  @stream_name "test-stream-#{System.system_time(:second)}"
  @consumer_name "test-consumer-#{System.system_time(:second)}"

  test "Stream and Consumer Lifecycle" do # Create a new stream
    {:ok, %Sequin.Stream{name: stream_name}} = Sequin.create_stream(@stream_name)

    # Create a consumer
    {:ok, %Sequin.Consumer{name: consumer_name}} = Sequin.create_consumer(@stream_name, @consumer_name, "test.>")

    # Send a message
    assert {:ok, %{published: 1}} = Sequin.send_message(@stream_name, "test.1", "Hello, Sequin!")

    # Receive and ack a message
    with {:ok, %Sequin.Message{} = message} <- Sequin.receive_message(@stream_name, @consumer_name),
        # do work
        :ok <- Sequin.ack_message(@stream_name, @consumer_name, message.ack_id) do
      IO.puts("Received and acked message: #{inspect(message)}")
    else
      {:error, error} ->
        IO.puts("Error: #{Exception.message(error)}")
    end

    # Delete the consumer
    {:ok, delete_consumer_res} = Sequin.delete_consumer(@stream_name, @consumer_name)

    # Delete the stream
    {:ok, delete_stream_res} = Sequin.delete_stream(@stream_name)
  end
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/sequin>.
