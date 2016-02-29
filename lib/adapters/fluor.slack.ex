defmodule Fluor.Slack do
  use Slack
  require Logger

  def handle_connect(slack, state) do
    {:ok, state}
  end

  def handle_message(message = %{type: "message"}, slack, state) do
    try do
      case :sub_type in message do
        false ->
          case slack.channels[message.channel] do
            nil -> :noop
            channel ->
              user = case message[:user] do
                       nil -> ""
                       u -> u
                     end
              case slack.users[user] do
                nil -> :noop
                user ->
                  case user.name do
                    "fluor" -> :noop
                    name ->
                      Fluor.to_xmpp channel.name, name, Slack.Utils.sanitize(message.text)
                  end
              end
          end
        _ -> :noop
      end
    rescue
      e in _ ->
        Logger.info "Failed in Slack.handle_message with #{Exception.message e}"
    catch
      e ->
        IO.inspect e
    end
    {:ok, state}
  end

  def handle_message(_message, _slack, state) do
    {:ok, state}
  end

  def handle_info({:say, message, channel_name}, slack, state) do
    try do
      channel_id = slack.channels |> Map.values
      |> Enum.find(fn(channel) -> channel.name == channel_name end)
      |> Map.get(:id)

      send_message(message, channel_id, slack)
    rescue
      e in _ ->
        Logger.info "Failed in Slack.:say with #{Exception.message e}"
    catch
      e ->
        IO.inspect e
    end
    {:ok, state}
  end
  def handle_info(_message, _slack, state), do: {:ok, state}

end
