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

  describe "read_file/1" do
    test "directory" do
      # arrange
      assert :ok = Storage.make_directory("/foo")

      assert {:error, :invalid_path} = Storage.read_file("/foo")
    end

    test "non-existant file" do
      assert {:error, :invalid_path} = Storage.read_file("/foo")
    end

    test "multiple writes" do
      # arrange
      assert :ok = Storage.create_file("/foo")
      assert :ok = Storage.write_file("/foo", "contents")
      assert :ok = Storage.write_file("/foo", "\nmore contents")

      assert {:ok, "contents\nmore contents"} = Storage.read_file("/foo")
    end
  end

  describe "move/2" do
    test "move directories" do
      # arrange
      assert :ok = Storage.make_directory("/foo")

      # act
      assert :ok = Storage.move("/foo", "/bar")

      # assert
      assert {:error, :invalid_path} = Storage.list_directory("/foo")
      assert {:ok, []} = Storage.list_directory("/bar")
    end

    test "move files" do
      # arrange
      assert :ok = Storage.create_file("/foo")

      # act
      assert :ok = Storage.move("/foo", "/bar")

      # assert
      assert {:error, :invalid_path} = Storage.read_file("/foo")
      assert {:ok, ""} = Storage.read_file("/bar")
    end

    test "move nested directories" do
      # arrange
      assert :ok = Storage.make_directory("/foo")
      assert :ok = Storage.make_directory("/bar")

      # act
      assert :ok = Storage.move("/foo", "/bar/foo")

      # assert
      assert {:error, :invalid_path} = Storage.list_directory("/foo")
      assert {:ok, ["foo"]} = Storage.list_directory("/bar")
      assert {:ok, []} = Storage.list_directory("/bar/foo")
    end

    test "move nested files" do
      # arrange
      assert :ok = Storage.create_file("/foo/bar")

      # act
      assert :ok = Storage.move("/foo/bar", "/foo/baz")

      # assert
      assert {:error, :invalid_path} = Storage.read_file("/foo/bar")
      assert {:ok, ""} = Storage.read_file("/foo/baz")
    end

    test "when source files already exists" do
      # arrange
      assert :ok = Storage.create_file("/foo/bar")
      assert :ok = Storage.create_file("/foo/baz")

      # act
      assert {:error, :invalid_path} = Storage.move("/foo/bar", "/foo/baz")

      # assert
      assert {:ok, ""} = Storage.read_file("/foo/bar")
      assert {:ok, ""} = Storage.read_file("/foo/baz")
    end

    test "when source directory already exists" do
      # arrange
      assert :ok = Storage.make_directory("/foo/bar")
      assert :ok = Storage.make_directory("/foo/baz")

      # act
      assert {:error, :invalid_path} = Storage.move("/foo/bar", "/foo/baz")

      # assert
      assert {:ok, []} = Storage.list_directory("/foo/bar")
      assert {:ok, []} = Storage.list_directory("/foo/baz")
    end

    test "when source directory doesn't exist" do
      # arrange
      assert :ok = Storage.make_directory("/foo/bar")
      assert :ok = Storage.create_file("/foo/bar/qux")

      # act
      assert :ok = Storage.move("/foo/bar", "/biz/baz")

      # assert
      assert {:error, :invalid_path} = Storage.list_directory("/foo/bar"), "target moved"

      assert {:ok, []} = Storage.list_directory("/foo"),
             "parent directory still exists, but target is no longer listed"

      assert {:ok, ["baz"]} = Storage.list_directory("/biz"),
             "new directory created and lists moved directory"

      assert {:ok, ["qux"]} = Storage.list_directory("/biz/baz"),
             "new directory moved along with contents"
    end
  end
end
