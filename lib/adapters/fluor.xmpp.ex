defmodule Fluor.XMPP do
  use GenServer
  require Logger

  alias Romeo.Connection
  alias Romeo.Stanza

  def start(opts) do
    GenServer.start(__MODULE__, opts, [])
  end

  def stop(pid) do
    try do
      GenServer.call(pid, :stop)
    catch
      :exit, _ -> Process.exit(pid, :forsed)
    end
    :ok
  end

  def message(pid, msg, room) do
    GenServer.cast(pid, {:message, msg, room})
  end

  # Callbacks

  def init(opts) do
    {:ok, pid} = Connection.start_link([jid: opts[:user],
                                        password: opts[:password],
                                        nickname: "fluor"
                                       ])
    {:ok, %{:pid => pid, :opts => opts}}
  end

  def handle_call(:stop, _from, state) do
    Connection.close state[:pid]
    {:stop, :normal, :ok, state}
  end

  def handle_cast({:message, msg, room}, state) do
    Connection.send(state[:pid],
                    Stanza.groupchat(room, msg))
    {:noreply, state}
  end

  def handle_info(:connection_ready, state) do
    Enum.each(
      state.opts[:rooms],
      fn room -> Connection.send(state.pid, Stanza.join(room, "fluor")) end
    )
    {:noreply, state}
  end

  def handle_info({:stanza, %Stanza.Presence{}}, state) do
    {:noreply, state}
  end

  def handle_info({:stanza, %Stanza.IQ{}}, state) do
    {:noreply, state}
  end

  def handle_info({:stanza, %Stanza.Message{}=msg}, state) do
    case msg.from.resource == "fluor" or msg.from.full in state.opts[:rooms] do
      true -> :ok
      false ->
        room = msg.from.full |> String.split("/") |> List.first
        Fluor.to_slack(room, msg.from.resource, msg.body)
    end
    {:noreply, state}
  end

  def handle_info(_data, state) do
    {:noreply, state}
  end
end
