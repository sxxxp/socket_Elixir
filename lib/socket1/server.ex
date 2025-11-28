defmodule Socket1.Server do
  import Socket

  def init do
    server = Socket.TCP.listen!(1337, packet: :line)
    IO.puts("Server listening on port 1337")
    client = server |> Socket.TCP.accept!()
    IO.puts("Client connected: #{inspect(client)}")

    echo(client, server)
    server |> Socket.Stream.close()
  end

  defp echo(sock, server) do
    case sock |> Socket.Stream.recv() do
      {:ok, message} ->
        IO.puts("Received message: #{message}")

        case message do
          "quit" <> _ ->
            reconnect(server)
            :ok

          nil ->
            IO.puts("Received nil")
            echo(sock, server)

          _ ->
            sock |> Socket.Stream.send!("echoed: " <> message)
            echo(sock, server)
        end

      {:error, :closed} ->
        sock |> Socket.Stream.close()
        IO.puts("Client closed connection.")
        :ok

      {:error, reason} ->
        sock |> Socket.Stream.close()
        IO.puts("Receive error: #{inspect(reason)}")
        :error
    end
  end

  defp reconnect(server) do
    try do
      client = server |> Socket.TCP.accept!(timeout: 10_000)
      throw(client)
    rescue
      e in Socket.Error ->
        if String.starts_with?(e.message, "timeout") do
          IO.puts("Timeouted")
          :timeout
        end
    catch
      client ->
        IO.puts("Client connected: #{inspect(client)}")
        echo(client, server)
    end
  end
end
