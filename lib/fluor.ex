defmodule Fluor do
  def init() do

    Agent.start_link(fn -> Map.new end, name: __MODULE__)

    {:ok, slack} = Fluor.Slack.start_link(Application.fetch_env!(:fluor, :slack_token), [])
    {:ok, xmpp} = Fluor.XMPP.start(Application.fetch_env!(:fluor, :jabber))

    update(:slack, slack)
    update(:xmpp, xmpp)
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
        message = "#{slack_from}@slack: #{slack_text}"

        Fluor.XMPP.message retrieve(:xmpp), message, room
    end
  end

  defp update(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end

  defp retrieve(key) do
    Agent.get(__MODULE__, &Map.get(&1, key))
  end

  defp get_room(room) do
    Application.fetch_env!(:fluor, :mapping)[room]
  end
end
