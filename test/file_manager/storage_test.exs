defmodule FileManager.StorageTest do
  # Note: async: false because the Storage service doesn't support asynchronous
  # test access.
  use FileManager.Test.Case.App, async: false

  alias FileManager.Storage
  doctest Storage

  describe "list_directory/1" do
    test "empty directory" do
      assert {:ok, []} = Storage.list_directory("/")
    end

    test "lists contents" do
      :ok = Storage.make_directory("/foo/bar")
      :ok = Storage.make_directory("/foo/baz")

      assert {:ok, contents} = Storage.list_directory("/foo")
      assert Enum.sort(contents) == ["bar", "baz"]
    end
  end
end
