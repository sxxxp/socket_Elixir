defmodule Socket1.Client do
  import Socket

  def connect do
    client = Socket.TCP.connect!("127.0.0.1", 1337, packet: :line)
    handel(client)
    client |> Socket.Stream.close()
    :ok
  end

  defp handel(client) do
    message = IO.gets("enter to send message: ")
    client |> Socket.Stream.send!(message)

    if message != "quit\n" do
      client |> Socket.Stream.recv!() |> IO.puts()
      handel(client)
    end
  end
end
