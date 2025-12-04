defmodule Socket3.Server do
  import Socket
  import Socket3.Tracker
  import Agent

  defp init do
    case Socket3.Tracker.start_link() do
      {:ok, _} ->
        IO.puts("Tracker has started.")
        :ok

      {:error, {:already_started, _}} ->
        IO.puts("[!] start_link has already been started.")
        :error

      {:error, {reason, _}} when is_atom(reason) ->
        IO.puts("[!] Failed to start Tracker: #{inspect(reason)}")
        :error

      {:error, _} ->
        IO.puts("[?] Got unknown error.")
        :unknown_error
    end
  end

  def start do
    case Process.whereis(Socket3.Tracker) do
      nil ->
        init()

      _pid ->
        :ok

      {:error, reason} ->
        IO.puts("[!] Failed to start Tracker: #{inspect(reason)}")
        :error
    end

    case Socket.TCP.listen(1337, packet: :line) do
      {:ok, server} ->
        IO.puts("Server listening on port 1337")
        IO.puts("Waiting for a client...")

        accept_loop(server)

      {:error, reason} ->
        IO.puts("[!] Failed to start server: #{inspect(reason)}")
        :error
    end
  end

  def accept_loop(server) do
    timeout = (Socket3.Tracker.get_count() == 0 && 60_000) || :infinity

    case Socket.TCP.accept(server, timeout: timeout) do
      {:ok, client} ->
        pid =
          spawn_link(fn ->
            IO.puts("Client connected: #{inspect(client)} - Starting new process.")
            broadcast_message("system", "#{inspect(client)} joined.")
            echo_client(self(), client)
            client_close(self(), client)
          end)

        Socket3.Tracker.add_client(pid, client)

        accept_loop(server)

      {:error, :closed} ->
        IO.puts("Server socket closed.")

      {:error, reason} ->
        IO.puts("[!] Accept error: #{inspect(reason)}")
    end
  end

  def echo_client(pid, sock) do
    case sock |> Socket.Stream.recv() do
      {:ok, message} when is_bitstring(message) ->
        IO.puts("Received #{inspect(sock)} message: #{message |> String.trim_trailing()}")

        case message do
          "quit" <> _ ->
            client_close(pid, sock)
            broadcast_message("system", "#{inspect(sock)} left.")
            IO.puts("#{inspect(sock)} sent 'quit'. Closing connection.")
            :ok

          _ ->
            broadcast_message(sock, message)
            echo_client(pid, sock)
        end

      {:ok, nil} ->
        broadcast_message("system", "#{inspect(sock)} left.")
        client_close(pid, sock)
        IO.puts("[!] Received nil (Client Disconnected).")
        :ok

      {:error, :closed} ->
        broadcast_message("system", "#{inspect(sock)} left.")
        client_close(pid, sock)
        IO.puts("[!] Client has already closed connection.")
        :ok

      {:error, reason} ->
        IO.puts("[!] Receive error: #{inspect(reason)}")
        :error
    end
  end

  defp broadcast_message(sender, data) do
    for sock <- Socket3.Tracker.get_clients(), sender != sock do
      data = data |> String.trim_trailing()

      case sock |> Socket.Stream.send("{#{inspect(sender)},#{data}}\n") do
        :ok -> :ok
        {:error, _} -> client_close(self(), sock)
      end
    end
  end

  defp client_close(pid, sock) do
    sock |> Socket.Stream.close()
    pid |> delete_client()
  end
end
