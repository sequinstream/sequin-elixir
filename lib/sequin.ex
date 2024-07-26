defmodule Sequin do
  @moduledoc """
  A lightweight Elixir SDK for sending, receiving, and acknowledging messages in [Sequin streams](https://github.com/sequinstream/sequin).

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
      IO.puts("Error sending message: \#{Exception.message(error)}")
  end

  # Receive a message
  with {:ok, %{message: message, ack_id: ack_id}} <- Sequin.receive_message(stream, consumer),
       :ok <- YourApp.process_message(message),
       :ok <- Sequin.ack_message(stream, consumer, ack_id) do
    IO.puts("Received and acked message: \#{inspect(message)}")
  else
    {:ok, nil} ->
      IO.puts("No messages available")

    {:error, error} ->
      IO.puts("Error: \#{Exception.message(error)}")
  end
  ```
  """

  alias Sequin.Consumer
  alias Sequin.Stream, as: SequinStream
  alias Sequin.Message

  @doc """
  [Send](https://github.com/sequinstream/sequin?tab=readme-ov-file#sending-messages) a message to a stream.
  """

  @spec send_message(stream :: String.t(), key :: String.t(), data :: String.t()) ::
          {:ok, %{published: integer()}} | {:error, Exception.t()}
  def send_message(stream, key, data)
      when is_binary(stream) and is_binary(key) and is_binary(data) do
    send_messages(stream, [%{key: key, data: data}])
  end

  @doc """
  Send a batch of messages (max 1,000).

  `send_messages/2` is all or nothing. Either all the messages are successfully sent, or none of the messages are sent.
  """
  @spec send_messages(
          stream :: String.t(),
          messages :: list(%{key: String.t(), data: String.t()})
        ) ::
          {:ok, %{published: integer()}} | {:error, Exception.t()}
  def send_messages(stream, messages) when is_binary(stream) and is_list(messages) do
    url = "/api/streams/#{stream}/messages"
    body = %{messages: messages}

    case Req.post(base_req(), url: url, json: body) do
      {:ok, %Req.Response{status: 200, body: %{"data" => %{"published" => count}}}} ->
        {:ok, %{published: count}}

      {:ok, %Req.Response{} = resp} ->
        {:error, exception(resp)}

      {:error, error} when is_exception(error) ->
        {:error, error}
    end
  end

  @doc """
  Receive a single message from a consumer.
  """
  @spec receive_message(stream :: String.t(), consumer :: String.t()) ::
          {:ok, %{message: Message.t(), ack_id: String.t()}} | {:error, Exception.t()}
  def receive_message(stream, consumer) when is_binary(stream) and is_binary(consumer) do
    case receive_messages(stream, consumer, batch_size: 1) do
      {:ok, []} ->
        {:ok, nil}

      {:ok, [message]} ->
        {:ok, message}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Receive a batch of messages from a consumer.

  `batch_size` defaults to 10.
  """
  @spec receive_messages(
          stream :: String.t(),
          consumer :: String.t(),
          opts :: [batch_size: integer()]
        ) ::
          {:ok, [%{message: Message.t(), ack_id: String.t()}]} | {:error, Exception.t()}
  def receive_messages(stream, consumer, opts \\ [])
      when is_binary(stream) and is_binary(consumer) and is_list(opts) do
    url = "/api/streams/#{stream}/consumers/#{consumer}/receive"
    body = %{batch_size: opts[:batch_size] || 10}

    case Req.post(base_req(), url: url, json: body) do
      {:ok, %Req.Response{status: 200, body: %{"data" => data}}} ->
        result =
          Enum.map(data, fn %{"message" => message, "ack_id" => ack_id} ->
            %{ack_id: ack_id, message: Message.decode(message)}
          end)

        {:ok, result}

      {:ok, %Req.Response{} = resp} ->
        {:error, exception(resp)}

      {:error, error} when is_exception(error) ->
        {:error, error}
    end
  end

  @doc """
  After processing a message, you can [acknowledge](https://github.com/sequinstream/sequin?tab=readme-ov-file#acking-messages) it using `ack_message/3`:

  Acks a single message for a consumer by ack_id.
  """
  @spec ack_message(
          stream :: String.t(),
          consumer :: String.t(),
          ack_id :: String.t()
        ) :: :ok | {:error, Exception.t()}
  def ack_message(stream, consumer, ack_id)
      when is_binary(stream) and is_binary(consumer) and is_binary(ack_id) do
    ack_messages(stream, consumer, [ack_id])
  end

  @doc """
  After processing messages, you can [acknowledge](https://github.com/sequinstream/sequin?tab=readme-ov-file#acking-messages) them using `ack_messages/3`:

  Acks a list of messages for a consumer by ack_id.
  """
  @spec ack_messages(
          stream :: String.t(),
          consumer :: String.t(),
          ack_ids :: [String.t()]
        ) :: :ok | {:error, Exception.t()}
  def ack_messages(stream, consumer, ack_ids)
      when is_binary(stream) and is_binary(consumer) and is_list(ack_ids) do
    url = "/api/streams/#{stream}/consumers/#{consumer}/ack"
    body = %{ack_ids: ack_ids}

    case Req.post(base_req(), url: url, json: body) do
      {:ok, %Req.Response{status: status}} when status in [200, 204] ->
        :ok

      {:ok, %Req.Response{} = resp} ->
        {:error, exception(resp)}

      {:error, error} when is_exception(error) ->
        {:error, error}
    end
  end

  @doc """
  Nacks a single message for a consumer by ack_id.
  """
  @spec nack_message(
          stream :: String.t(),
          consumer :: String.t(),
          ack_id :: String.t()
        ) :: :ok | {:error, Exception.t()}
  def nack_message(stream, consumer, ack_id)
      when is_binary(stream) and is_binary(consumer) and is_binary(ack_id) do
    nack_messages(stream, consumer, [ack_id])
  end

  @doc """
  Nacks a list of messages for a consumer by ack_id.
  """
  @spec nack_messages(
          stream :: String.t(),
          consumer :: String.t(),
          ack_ids :: [String.t()]
        ) :: :ok | {:error, Exception.t()}
  def nack_messages(stream, consumer, ack_ids)
      when is_binary(stream) and is_binary(consumer) and is_list(ack_ids) do
    url = "/api/streams/#{stream}/consumers/#{consumer}/nack"
    body = %{ack_ids: ack_ids}

    case Req.post(base_req(), url: url, json: body) do
      {:ok, %Req.Response{status: status}} when status in [200, 204] ->
        :ok

      {:ok, %Req.Response{} = resp} ->
        {:error, exception(resp)}

      {:error, error} when is_exception(error) ->
        {:error, error}
    end
  end

  @doc """
  For a full list of options, see: [Sequin.Stream](Sequin.Stream.html)
  """
  @spec create_stream(stream :: String.t(), opts :: Keyword.t()) ::
          {:ok, SequinStream.t()} | {:error, Exception.t()}
  def create_stream(name, options \\ []) when is_binary(name) and is_list(options) do
    url = "/api/streams"
    body = Map.new([{:name, name} | options])

    case Req.post(base_req(), url: url, json: body) do
      {:ok, %Req.Response{status: 200, body: stream}} ->
        {:ok, SequinStream.decode(stream)}

      {:ok, %Req.Response{} = resp} ->
        {:error, exception(resp)}

      {:error, error} when is_exception(error) ->
        {:error, error}
    end
  end

  @spec delete_stream(stream :: String.t()) ::
          {:ok, %{deleted: true, id: String.t()}} | {:error, Exception.t()}
  def delete_stream(stream) when is_binary(stream) do
    url = "/api/streams/#{stream}"

    case Req.delete(base_req(), url: url) do
      {:ok, %Req.Response{status: 200, body: %{"deleted" => true, "id" => ^stream}}} ->
        :ok

      {:ok, %Req.Response{} = resp} ->
        {:error, exception(resp)}

      {:error, error} when is_exception(error) ->
        {:error, error}
    end
  end

  @doc """
  Creates a new consumer for a stream.

  For a full list of options, see: [Sequin.Consumer](Sequin.Consumer.html)
  """
  @spec create_consumer(
          stream :: String.t(),
          name :: String.t(),
          filter :: String.t()
        ) :: {:ok, Consumer.t()} | {:error, Exception.t()}
  def create_consumer(stream, name, filter, opts \\ [])
      when is_binary(stream) and is_binary(name) and is_binary(filter) and is_list(opts) do
    url = "/api/streams/#{stream}/consumers"
    body = Map.new([{:name, name}, {:filter_key_pattern, filter} | opts])

    case Req.post(base_req(), url: url, json: body) do
      {:ok, %Req.Response{status: 200, body: consumer}} ->
        {:ok, Consumer.decode(consumer)}

      {:ok, %Req.Response{} = resp} ->
        {:error, exception(resp)}

      {:error, error} when is_exception(error) ->
        {:error, error}
    end
  end

  @spec delete_consumer(stream :: String.t(), consumer :: String.t()) ::
          :ok | {:error, Exception.t()}
  def delete_consumer(stream, consumer)
      when is_binary(stream) and is_binary(consumer) do
    url = "/api/streams/#{stream}/consumers/#{consumer}"

    case Req.delete(base_req(), url: url) do
      {:ok, %Req.Response{status: status}} when status in [200, 204] ->
        :ok

      {:ok, %Req.Response{} = resp} ->
        {:error, exception(resp)}

      {:error, error} when is_exception(error) ->
        {:error, error}
    end
  end

  defp exception(%Req.Response{} = resp) do
    case resp.body do
      %{"summary" => summary} ->
        %Sequin.Error{message: "Sequin error: #{resp.status}: #{summary}"}

      _ ->
        %Sequin.Error{message: "Sequin error: #{resp.status}"}
    end
  end

  defp base_req do
    Req.new(
      base_url: base_url(),
      max_retries: 3
    )
  end

  defp base_url do
    Application.get_env(:sequin, :base_url) || "http://localhost:7376"
  end
end
