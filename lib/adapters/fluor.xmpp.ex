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
                                        nickname: "fluor",
                                        resource: opts[:resource]
                                       ])
    {:ok, %{:pid => pid, :opts => opts, :connected => false, :messages => []}}
  end

  def handle_call(:stop, _from, state) do
    Connection.close state[:pid]
    {:stop, :normal, :ok, state}
  end

  def handle_cast({:message, msg, room}, state = %{:messages => msgs}) do
    case state.connected do
      false -> {:noreply, %{state | :messages => msgs ++ [%{:text => msg, :room => room}]}}
      true ->
        Connection.send(state[:pid], Stanza.groupchat(room, msg))
        {:noreply, state}
    end
  end

  def handle_info(:connection_ready, state = %{:messages => msgs}) do
    Enum.each(
      state.opts[:rooms],
      fn room ->
        Connection.send(state.pid,
                        Stanza.join(room, "#{state.opts[:resource]}`")
        )
        end
    )
    Enum.each msgs, fn m -> Connection.send(state[:pid],Stanza.groupchat(m.room, m.text)) end
    {:noreply, %{state | :connected => true}}
  end

  def handle_info({:stanza, %Stanza.Presence{}}, state) do
    {:noreply, state}
  end

  def handle_info({:stanza, %Stanza.IQ{}}, state) do
    {:noreply, state}
  end

  def handle_info({:stanza, %Stanza.Message{}=msg}, state) do
    case msg.from.resource == "fluor" or
    msg.from.full in state.opts[:rooms] or
    String.contains?(msg.from.resource, "`") or
    not (msg.to.resource == "fluor") do
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
