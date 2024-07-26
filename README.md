# Sequin

A lightweight Elixir SDK for sending, receiving, and acknowledging messages in [Sequin](https://github.com/sequinstream/sequin).

See the [docs on Hex](https://hexdocs.pm/sequin_client/Sequin.html).

## Installation

Sequin can be installed by adding `sequin` to your list of dependencies in `mix.exs`:

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

You'll predominantly use `Sequin` to send, receive, and acknowledge [messages](https://github.com/sequinstream/sequin?tab=readme-ov-file#messages) in Sequin:

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

To test code that uses Sequin, you can create temporary streams and consumers. Here's an example using ExUnit:

```elixir
defmodule SequinTest do
  use ExUnit.Case
  alias Sequin

  @stream_name "test-stream-#{System.system_time(:second)}"
  @consumer_name "test-consumer-#{System.system_time(:second)}"

  setup do
    {:ok, _} = Sequin.create_stream(@stream_name)
    {:ok, _} = Sequin.create_consumer(@stream_name, @consumer_name, "test.>")

    on_exit(fn ->
      # Delete the consumer
      {:ok, _} = Sequin.delete_consumer(@stream_name, @consumer_name)

      # Delete the stream
      {:ok, _} = Sequin.delete_stream(@stream_name)
    end)

    :ok
  end

  # Create a new stream
  test "Stream and Consumer Lifecycle" do
    # Send a message
    assert {:ok, %{published: 1}} = Sequin.send_message(@stream_name, "test.1", "Hello, Sequin!")
    
    assert YourApp.handle_messages()
  end
end
```
