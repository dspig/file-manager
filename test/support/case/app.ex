defmodule FileManager.Test.Case.App do
  defmacro __using__(opts) do
    async = Keyword.get(opts, :async, true)

    quote do
      use ExUnit.Case, async: unquote(async)

      setup _ do
        :ok = FileManager.Storage.reset()
      end
    end
  end
end
