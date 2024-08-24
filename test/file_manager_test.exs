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
      FileManager.make_directory(session, "/usr/local")
    end

    test "defaults to /", %{session: session} do
      assert {:ok, "/"} = FileManager.current_working_directory(session)
    end

    test "after changing directory", %{session: session} do
      assert {:ok, _directory} = FileManager.change_directory(session, "/usr/local")
      assert {:ok, "/usr/local"} = FileManager.current_working_directory(session)
    end
  end

  describe "change_directory/2" do
    setup %{session: session} do
      FileManager.make_directory(session, "/usr/local/bin")
    end

    test "root directory", %{session: session} do
      assert {:ok, "/"} = FileManager.change_directory(session, "/")
      assert {:ok, "/"} = FileManager.change_directory(session, ".")

      assert {:ok, "/"} = FileManager.change_directory(session, ".."),
             "parent of root is root (similar to unix 'cd')"

      assert {:ok, "/"} = FileManager.change_directory(session, "../..")
    end

    test "nested directories", %{session: session} do
      assert {:ok, "/usr"} = FileManager.change_directory(session, "usr"), "relative to cwd"

      assert {:ok, "/usr/local"} = FileManager.change_directory(session, "local"),
             "relative to cwd"

      assert {:ok, "/usr"} = FileManager.change_directory(session, "./.."),
             "resolves current and parent directory"
    end

    test "absolute paths", %{session: session} do
      assert {:ok, "/usr/local/bin"} = FileManager.change_directory(session, "/usr/local/bin")
    end

    test "invalid paths", %{session: session} do
      assert {:error, :invalid_path} = FileManager.change_directory(session, "bix")

      assert {:ok, "/usr/local/bin"} = FileManager.change_directory(session, "/usr/local/bin"),
             "absolute paths"

      assert {:error, :invalid_path} = FileManager.change_directory(session, "bix")
    end

    test "change directory to a file", %{session: session} do
      assert :ok = FileManager.create_file(session, "/biz")
      assert {:error, :invalid_path} = FileManager.change_directory(session, "/biz")
    end
  end

  describe "make_directory/2" do
    test "nested directories", %{session: session} do
      assert :ok = FileManager.make_directory(session, "/usr/local/bin")
      assert {:ok, ["bin"]} = FileManager.list_directory(session, "/usr/local")
    end

    test "directory already exists", %{session: session} do
      assert :ok = FileManager.make_directory(session, "/usr/local/bin")
      assert {:error, :already_exists} = FileManager.make_directory(session, "/usr/local/bin")
      assert {:error, :already_exists} = FileManager.make_directory(session, "/usr/local")
      assert {:error, :already_exists} = FileManager.make_directory(session, "/usr")
    end

    test "already exists as a file", %{session: session} do
      assert :ok = FileManager.create_file(session, "/usr/local")
      assert {:error, :already_exists} = FileManager.make_directory(session, "/usr/local")
    end

    test "empty directory name", %{session: session} do
      assert {:error, :invalid_path} = FileManager.make_directory(session, "")

      assert :ok = FileManager.make_directory(session, "/usr/local/bin")
      assert {:ok, _cwd} = FileManager.change_directory(session, "/usr/local/bin")

      assert {:error, :invalid_path} = FileManager.make_directory(session, "")
    end
  end

  describe "list_directory/2" do
    test "list contents", %{session: session} do
      assert {:ok, []} = FileManager.list_directory(session, "/")

      assert :ok = FileManager.make_directory(session, "/usr")
      assert :ok = FileManager.make_directory(session, "/etc")
      assert :ok = FileManager.create_file(session, "/bin")
      assert {:ok, contents} = FileManager.list_directory(session, "/")
      assert Enum.sort(contents) == ["bin", "etc", "usr"]
    end

    test "absolute paths", %{session: session} do
      assert :ok = FileManager.make_directory(session, "/usr/local/bin")

      assert {:ok, ["usr"]} = FileManager.list_directory(session, "/")
      assert {:ok, ["local"]} = FileManager.list_directory(session, "/usr")
      assert {:ok, ["bin"]} = FileManager.list_directory(session, "/usr/local")
      assert {:ok, []} = FileManager.list_directory(session, "/usr/local/bin")
    end

    test "current working directory", %{session: session} do
      assert {:ok, []} = FileManager.list_directory(session)

      assert :ok = FileManager.make_directory(session, "/usr/local/bin")
      assert {:ok, ["usr"]} = FileManager.list_directory(session)

      assert {:ok, _cwd} = FileManager.change_directory(session, "usr")
      assert {:ok, ["local"]} = FileManager.list_directory(session)
    end

    test "non-existent directory", %{session: session} do
      assert {:error, :invalid_path} = FileManager.list_directory(session, "/usr")
    end

    test "listing a file", %{session: session} do
      assert :ok = FileManager.create_file(session, "/usr")
      assert {:error, :invalid_path} = FileManager.list_directory(session, "/usr")
    end
  end

  describe "delete_directory/2" do
    test "deleting root", %{session: session} do
      assert {:error, :invalid_path} = FileManager.delete_directory(session, "/")
    end

    test "deleting current working directory", %{session: session} do
      assert :ok = FileManager.make_directory(session, "/usr")
      assert {:ok, _cwd} = FileManager.change_directory(session, "/usr")
      assert {:error, :invalid_path} = FileManager.delete_directory(session, ".")
      assert {:error, :invalid_path} = FileManager.delete_directory(session, "..")
      assert {:error, :invalid_path} = FileManager.delete_directory(session, "../foo")
    end

    test "deleting parent of current working directory", %{session: session} do
      assert :ok = FileManager.make_directory(session, "/usr/local/bin")
      assert {:ok, _cwd} = FileManager.change_directory(session, "/usr/local/bin")
      assert {:error, :invalid_path} = FileManager.delete_directory(session, "/usr/local")
    end

    test "deleting a non-existent directory", %{session: session} do
      assert {:error, :invalid_path} = FileManager.delete_directory(session, "/usr")
    end

    test "deleting a sub-tree", %{session: session} do
      assert :ok = FileManager.make_directory(session, "/usr/local/bin")
      assert :ok = FileManager.delete_directory(session, "/usr")
      assert {:ok, []} = FileManager.list_directory(session, "/")
      assert {:error, :invalid_path} = FileManager.list_directory(session, "/usr/local")
    end

    test "deleting a file", %{session: session} do
      assert :ok = FileManager.create_file(session, "/usr")
      assert {:error, :invalid_path} = FileManager.delete_directory(session, "/usr")
    end
  end

  describe "create_file/2" do
    test "empty file_name, root directory", %{session: session} do
      assert {:error, :invalid_path} = FileManager.create_file(session, "")
    end

    test "empty file_name, nested directory", %{session: session} do
      assert :ok = FileManager.make_directory(session, "/usr/local/bin")
      assert {:ok, _cwd} = FileManager.change_directory(session, "/usr/local/bin")

      assert {:error, :invalid_path} = FileManager.create_file(session, "")
    end

    test "relative paths", %{session: session} do
      assert :ok = FileManager.create_file(session, "usr")
      assert {:ok, ["usr"]} = FileManager.list_directory(session)

      assert :ok = FileManager.create_file(session, "etc/passwd")
      assert {:ok, ["passwd"]} = FileManager.list_directory(session, "/etc")
    end

    test "create nested directories", %{session: session} do
      assert :ok = FileManager.create_file(session, "/usr/local/lib/foo")
      assert {:ok, ["lib"]} = FileManager.list_directory(session, "/usr/local")
      assert {:ok, ["foo"]} = FileManager.list_directory(session, "/usr/local/lib")
    end

    test "part of the path is not a directory", %{session: session} do
      assert :ok = FileManager.create_file(session, "/usr")
      assert {:error, :invalid_path} = FileManager.create_file(session, "/usr/bin")
    end
  end

  describe "write_file/3" do
    test "empty file_name, root directory", %{session: session} do
      assert {:error, :invalid_path} = FileManager.write_file(session, "", "Hello, world!")
    end

    test "empty file_name, nested directory", %{session: session} do
      assert :ok = FileManager.make_directory(session, "/usr/local/bin")
      assert {:ok, _cwd} = FileManager.change_directory(session, "/usr/local/bin")

      assert {:error, :invalid_path} = FileManager.write_file(session, "", "Hello, world!")
    end

    test "target is a directory", %{session: session} do
      assert :ok = FileManager.make_directory(session, "/usr/local/bin")

      assert {:error, :invalid_path} =
               FileManager.write_file(session, "/usr/local/bin", "Hello, world!")
    end

    test "relative paths", %{session: session} do
      assert :ok = FileManager.make_directory(session, "/usr/local/bin")
      assert {:ok, _cwd} = FileManager.change_directory(session, "/usr/local/bin")
      assert :ok = FileManager.create_file(session, "../tmp")
      assert :ok = FileManager.write_file(session, "../tmp", "Hello, world!")
    end

    test "multiple writes", %{session: session} do
      assert :ok = FileManager.create_file(session, "tmp")
      assert :ok = FileManager.write_file(session, "tmp", "Hello, world!")
      assert :ok = FileManager.write_file(session, "tmp", "Hola, mundo!")
    end
  end

  describe "read_file/2" do
    test "empty file_name, root directory", %{session: session} do
      assert {:error, :invalid_path} = FileManager.read_file(session, "")
    end

    test "empty file_name, nested directory", %{session: session} do
      # arrange
      assert :ok = FileManager.make_directory(session, "/usr/local/bin")
      assert {:ok, _cwd} = FileManager.change_directory(session, "/usr/local/bin")

      assert {:error, :invalid_path} = FileManager.read_file(session, "")
    end

    test "target is a directory", %{session: session} do
      # arrange
      assert :ok = FileManager.make_directory(session, "/usr/local/bin")

      assert {:error, :invalid_path} =
               FileManager.read_file(session, "/usr/local/bin")
    end

    test "relative paths", %{session: session} do
      # arrange
      assert :ok = FileManager.make_directory(session, "/usr/local/bin")
      assert {:ok, _cwd} = FileManager.change_directory(session, "/usr/local/bin")
      assert :ok = FileManager.create_file(session, "../tmp")
      assert :ok = FileManager.write_file(session, "../tmp", "Hello, world!")

      assert {:ok, "Hello, world!"} = FileManager.read_file(session, "../tmp")
    end

    test "multiple writes", %{session: session} do
      # arrange
      assert :ok = FileManager.create_file(session, "tmp")
      assert :ok = FileManager.write_file(session, "tmp", "Hello, world!")
      assert :ok = FileManager.write_file(session, "tmp", "Hola, mundo!")

      assert {:ok, "Hello, world!Hola, mundo!"} = FileManager.read_file(session, "tmp")
    end

    test "multi-line write", %{session: session} do
      # arrange
      assert :ok = FileManager.create_file(session, "tmp")

      assert :ok =
               FileManager.write_file(session, "tmp", """
               Hello, world!
               Hola, mundo!\
               """)

      assert {:ok, "Hello, world!\nHola, mundo!"} = FileManager.read_file(session, "tmp")
    end
  end

  describe "move/3" do
    test "empty file_name, root directory", %{session: session} do
      assert {:error, :invalid_path} = FileManager.move(session, "", "/foo")
      assert {:error, :invalid_path} = FileManager.move(session, "/foo", "")
    end

    test "empty file_name, nested directory", %{session: session} do
      # arrange
      assert :ok = FileManager.make_directory(session, "/usr/local/bin")
      assert {:ok, _cwd} = FileManager.change_directory(session, "/usr/local")

      assert {:error, :invalid_path} = FileManager.move(session, "", "bin")
      assert {:error, :invalid_path} = FileManager.move(session, "bin", "")
    end

    test "current working directory", %{session: session} do
      # arrange
      assert :ok = FileManager.make_directory(session, "usr")

      # act
      assert :ok = FileManager.move(session, "usr", "bin")

      # assert
      assert {:ok, ["bin"]} = FileManager.list_directory(session)
      assert {:ok, ["bin"]} = FileManager.list_directory(session, "/")
    end
  end

  test "changes persist across different sessions", %{session: session} do
    assert {:ok, other_session} = FileManager.open_session()

    # pre-condition
    assert {:ok, []} = FileManager.list_directory(other_session, "/")

    # arrange
    assert :ok = FileManager.make_directory(session, "/usr/local/bin")

    assert {:ok, ["usr"]} = FileManager.list_directory(other_session, "/")
    assert {:ok, ["bin"]} = FileManager.list_directory(other_session, "/usr/local")
  end
end
