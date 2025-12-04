defmodule Tools do
  defmacro while(condition, do: side_effect) do
    quote do
      while_fun = fn recurs ->
        if unquote(condition) do
          unquote(side_effect)
          recurs.(recurs)
        end
      end

      while_fun.(while_fun)
    end
  end
end
