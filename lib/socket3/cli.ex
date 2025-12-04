defmodule Socket3.CLI do
  def main(_args) do
    IO.puts("Starting Socket Server...")
    Socket3.Server.start()
  end
end
