defmodule MsFs.SessionTest do
  use ExUnit.Case
  alias MsFs.Session
  doctest Session

  test "close/1 with invalid session" do
    assert {:error, :invalid_session} = Session.close(make_ref())
  end

  test "current_working_directory/1 with invalid session" do
    assert {:error, :invalid_session} = Session.current_working_directory(make_ref())
  end
end
