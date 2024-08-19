defmodule FileManagerTest do
  # Note: async: false because the Storage service doesn't support asynchronous
  # test access.
  use FileManager.Test.Case.App, async: false

  setup do
    {:ok, session} = FileManager.open_session()
    [session: session]
  end

  test "open_session/1" do
    assert {:ok, _session} = FileManager.open_session()
  end

  test "current_working_directory/0", %{session: session} do
    assert {:ok, "/"} = FileManager.current_working_directory(session)
  end

  test "list_directory/2", %{session: session} do
    assert {:ok, []} = FileManager.list_directory(session, "/")
  end

  test "make_directory/2", %{session: session} do
    assert :ok = FileManager.make_directory(session, "/foo/bar/baz")
    assert {:ok, ["foo"]} = FileManager.list_directory(session, "/")
    assert {:ok, ["bar"]} = FileManager.list_directory(session, "/foo")
    assert {:ok, ["baz"]} = FileManager.list_directory(session, "/foo/bar")
  end
end
