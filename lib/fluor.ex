defmodule Fluor do
  def init() do

    Agent.start_link(fn -> Map.new end, name: __MODULE__)

    {:ok, slack} = Fluor.Slack.start_link(Application.fetch_env!(:fluor, :slack_token), [])
    # {:ok, xmpp} = Fluor.XMPP.start(Application.fetch_env!(:fluor, :jabber))

    update(:slack, slack)
    # update(:xmpp, xmpp)
  end

  def to_slack(xmpp_room, xmpp_from, xmpp_text) do
    case get_room(xmpp_room) do
      nil -> :noop
      room ->
        message = "*#{xmpp_from}@c.j.r*: #{xmpp_text}"
        send retrieve(:slack), {:say, message, room}
    end
  end

  def to_xmpp(slack_room, slack_from, slack_text) do
    case get_room(slack_room) do
      nil -> :noop
      room ->
        Fluor.XMPP.message get_or_login_xmpp(slack_from), slack_text, room
    end
  end

  def add_slack_user(slack_from) do
    get_or_login_xmpp(slack_from)
  end

  def remove_slack_user(slack_from) do
    case retrieve({:xmpp, slack_from}) do
      nil -> :ok
      pid ->
        Fluor.XMPP.stop(pid)
        delete({:xmpp, slack_from})
    end
  end

  defp get_or_login_xmpp(slack_from) do
    case retrieve({:xmpp, slack_from}) do
      nil ->
        login_xmpp(slack_from)
      pid ->
        pid
    end
  end

  def login_xmpp(slack_from) do
    opts = Application.fetch_env!(:fluor, :jabber)
    {:ok, xmpp} = Fluor.XMPP.start(opts ++ [resource: slack_from])
    update({:xmpp, slack_from}, xmpp)
    xmpp
  end

  defp update(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end

  defp retrieve(key) do
    Agent.get(__MODULE__, &Map.get(&1, key))
  end

  defp delete(key) do
    Agent.get(__MODULE__, &Map.delete(&1, key))
  end

  defp get_room(room) do
    Application.fetch_env!(:fluor, :mapping)[room]
  end
end
