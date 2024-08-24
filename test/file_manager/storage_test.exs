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
      # arrange
      assert :ok = Storage.make_directory("/foo/bar")
      assert :ok = Storage.make_directory("/foo/baz")

      assert {:ok, contents} = Storage.list_directory("/foo")
      assert Enum.sort(contents) == ["bar", "baz"]
    end
  end

  describe "delete_directory/1" do
    test "non-empty directory" do
      assert :ok = Storage.make_directory("/foo/bar")
      assert :ok = Storage.delete_directory("/foo")
    end

    test "non-existent directory" do
      assert {:error, :invalid_path} = Storage.delete_directory("/foo")
    end

    test "root directory" do
      assert {:error, :invalid_path} = Storage.delete_directory("/")
    end
  end

  describe "write_file/2" do
    test "directory" do
      # arrange
      assert :ok = Storage.make_directory("/foo")

      assert {:error, :invalid_path} = Storage.write_file("/foo", "contents")
    end

    test "non-existant file" do
      assert {:error, :invalid_path} = Storage.write_file("/foo", "contents")
    end

    test "multiple writes" do
      # arrange
      assert :ok = Storage.create_file("/foo")

      assert :ok = Storage.write_file("/foo", "contents")
      assert :ok = Storage.write_file("/foo", "more contents")
    end
  end
end
