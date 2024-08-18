defmodule MsFs.Session do
  @moduledoc """
  This modules is responsible for managing file system sessions. To interact
  with the file system, callers need to first open a session. The session
  maintains the caller's current working directory.
  """
  use GenServer

  defstruct current_working_directory: "/"

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:new_session}, _from, sessions) do
    id = make_ref()
    {:reply, {:ok, id}, Map.put_new(sessions, id, %__MODULE__{})}
  end

  @doc """
  Open a file system session.

  ## Examples
      iex> {:ok, session} = MsFs.Session.open()
      {:ok, session}
  """
  def open do
    GenServer.call(__MODULE__, {:new_session})
  end
end
