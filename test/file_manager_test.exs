defmodule FileManagerTest do
  # Note: async: false because the Storage service doesn't support asynchronous
  # test access.
  use FileManager.Test.Case.App, async: false
  doctest FileManager

  setup do
    {:ok, session} = FileManager.open_session()
    [session: session]
  end

  describe "current_working_directory/0" do
    setup %{session: session} do
      FileManager.make_directory(session, "/foo/bar")
    end

    test "defaults to /", %{session: session} do
      assert {:ok, "/"} = FileManager.current_working_directory(session)
    end

    test "after changing directory", %{session: session} do
      assert {:ok, _directory} = FileManager.change_directory(session, "/foo/bar")
      assert {:ok, "/foo/bar"} = FileManager.current_working_directory(session)
    end
  end

  describe "change_directory/2" do
    setup %{session: session} do
      FileManager.make_directory(session, "/foo/bar/baz")
    end

    test "root directory", %{session: session} do
      assert {:ok, "/"} = FileManager.change_directory(session, "/")
      assert {:ok, "/"} = FileManager.change_directory(session, ".")

      assert {:ok, "/"} = FileManager.change_directory(session, ".."),
             "parent of root is root (similar to unix 'cd')"

      assert {:ok, "/"} = FileManager.change_directory(session, "../..")
    end

    test "nested directories", %{session: session} do
      assert {:ok, "/foo"} = FileManager.change_directory(session, "foo"), "relative to cwd"
      assert {:ok, "/foo/bar"} = FileManager.change_directory(session, "bar"), "relative to cwd"

      assert {:ok, "/foo"} = FileManager.change_directory(session, "./.."),
             "resolves current and parent directory"
    end

    test "absolute paths", %{session: session} do
      assert {:ok, "/foo/bar/baz"} = FileManager.change_directory(session, "/foo/bar/baz")
    end

    test "invalid paths", %{session: session} do
      assert {:error, :invalid_path} = FileManager.change_directory(session, "bix")

      assert {:ok, "/foo/bar/baz"} = FileManager.change_directory(session, "/foo/bar/baz"),
             "absolute paths"

      assert {:error, :invalid_path} = FileManager.change_directory(session, "bix")
    end
  end

  test "make_directory/2", %{session: session} do
    assert :ok = FileManager.make_directory(session, "/foo/bar/baz")
    assert {:ok, ["baz"]} = FileManager.list_directory(session, "/foo/bar")
  end

  test "list_directory/2", %{session: session} do
    assert {:ok, []} = FileManager.list_directory(session, "/")
    assert {:ok, []} = FileManager.list_directory(session)

    assert :ok = FileManager.make_directory(session, "/foo/bar/baz")

    assert {:ok, ["foo"]} = FileManager.list_directory(session, "/")
    assert {:ok, ["foo"]} = FileManager.list_directory(session), "default path is cwd"

    assert {:ok, ["bar"]} = FileManager.list_directory(session, "/foo")
    assert {:ok, ["baz"]} = FileManager.list_directory(session, "/foo/bar")
    assert {:ok, []} = FileManager.list_directory(session, "/foo/bar/baz")
  end
end
