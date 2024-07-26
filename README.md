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
