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

    test "multiple entries" do
      :ok = Storage.make_directory("/foo/bar")
      :ok = Storage.make_directory("/foo/baz")

      assert {:ok, contents} = Storage.list_directory("/foo")
      assert Enum.sort(contents) == ["bar", "baz"]
    end
  end

  describe "delete_directory/" do
    test "non-empty directory" do
      :ok = Storage.make_directory("/foo/bar")

      assert :ok = Storage.delete_directory("/foo")
    end

    test "non-existent directory" do
      assert {:error, :invalid_path} = Storage.delete_directory("/foo")
    end

    test "root directory" do
      assert {:error, :invalid_path} = Storage.delete_directory("/")
    end
  end
end
