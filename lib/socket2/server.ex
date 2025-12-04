defmodule Socket2.Server do
  import Socket
  import Socket2.Tracker
  import Agent

  def start do
    case Socket2.Tracker.start_link() do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    {:ok, server} = Socket.TCP.listen(1337, packet: :line)
    IO.puts("Server listening on port 1337")

    accept_loop(server)
  end

  def accept_loop(server) do
    IO.puts("Waiting for a client...")
    timeout = (Socket2.Tracker.get() == 0 && 10_000) || :infinity

    case Socket.TCP.accept(server, timeout: timeout) do
      {:ok, client} ->
        spawn_link(fn ->
          IO.puts("Client connected: #{inspect(client)} - Starting new process.")
          Socket2.Tracker.increment()
          echo_client(client)
          Socket.Stream.close(client)
        end)

        accept_loop(server)

      {:error, :closed} ->
        IO.puts("Server socket closed.")

      {:error, reason} ->
        IO.puts("Accept error: #{inspect(reason)}")
    end
  end

  def echo_client(sock) do
    case sock |> Socket.Stream.recv() do
      {:ok, message} ->
        IO.puts("Received #{inspect(sock)} message: #{message}")

        case message do
          "quit" <> _ ->
            Socket2.Tracker.decrement()
            IO.puts("#{inspect(sock)} sent 'quit'. Closing connection.")
            :ok

          nil ->
            IO.puts("Received nil (Client Disconnected).")
            :ok

          _ ->
            sock |> Socket.Stream.send!("echoed: " <> message)
            echo_client(sock)
        end

      {:error, :closed} ->
        Socket2.Tracker.decrement()
        sock |> Socket.Stream.close()
        IO.puts("Client closed connection.")
        :ok

      {:error, reason} ->
        IO.puts("Receive error: #{inspect(reason)}")
        :error
    end
  end
end
