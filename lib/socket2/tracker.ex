defmodule Socket2.Tracker do
  use Agent

  def start_link do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  def get do
    Agent.get(__MODULE__, & &1)
  end

  def increment do
    Agent.update(__MODULE__, &(&1 + 1))
  end

  def decrement do
    Agent.update(__MODULE__, &(&1 - 1))
  end
end
