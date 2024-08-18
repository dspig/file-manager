defmodule FileManager.SessionTest do
  use ExUnit.Case
  alias FileManager.Session
  doctest Session

  describe "close/1" do
    test "invalid session" do
      assert {:error, :invalid_session} = Session.close(make_ref())
    end
  end

  describe "current_working_directory/1" do
    test "invalid session" do
      assert {:error, :invalid_session} = Session.current_working_directory(make_ref())
    end
  end

  describe "change_directory/2" do
    setup do
      {:ok, session} = Session.open()
      [session: session]
    end

    test "root directory", %{session: session} do
      assert {:ok, "/"} = Session.change_directory(session, "/")
    end

    test "relative path", %{session: session} do
      assert {:ok, "/foo"} = Session.change_directory(session, "foo")
      assert {:ok, "/foo/bar"} = Session.change_directory(session, "bar")
    end

    test "absolute path", %{session: session} do
      assert {:ok, "/foo"} = Session.change_directory(session, "/foo")
      assert {:ok, "/bar"} = Session.change_directory(session, "/bar")
    end

    test "parent directory", %{session: session} do
      assert {:ok, "/foo"} = Session.change_directory(session, "foo/bar/..")
      assert {:ok, "/"} = Session.change_directory(session, "..")

      assert {:ok, "/"} = Session.change_directory(session, ".."),
             "parent of root is root (similar behavior to unix 'cd')"
    end

    test "current directory", %{session: session} do
      assert {:ok, "/foo"} = Session.change_directory(session, "foo/./")
      assert {:ok, "/foo"} = Session.change_directory(session, "./")
      assert {:ok, "/foo"} = Session.change_directory(session, ".")
    end
  end
end
