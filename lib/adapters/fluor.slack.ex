defmodule Fluor.Slack do
  use Slack
  require Logger

  def handle_connect(slack, state) do
    # Enum.each(slack.users, fn {_, %{name: name}} -> Fluor.add_slack_user(name) end)
    {:ok, state}
  end

  def handle_message(message = %{type: "message"}, slack, state) do
    try do
      atts = case message[:attachments] do
               nil ->
                 case not(message[:message] == nil) and not(message[:message][:attachments] == nil) do
                   true ->
                     message[:message][:attachments]
                   false ->
                     nil
                 end
               _ -> message[:attachments]
             end
      case atts do
        nil ->
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
                      Fluor.to_xmpp channel.name, name, Fluor.Slack.Utils.sanitize(message.text, slack)
                  end
              end
          end
        _ ->
          atts |> Enum.each(fn att ->
            text = att[:text]
            title = att[:title]
            img = att[:image_url]

            msg = case text == nil do
                    true ->
                      case img == nil do
                        true -> nil
                        false -> img
                      end
                    false ->
                      txt = case text == nil do
                              true -> ""
                              false -> text
                            end
                      ttl = case title == nil do
                              true -> ""
                              false -> title
                            end
                      "#{txt} #{ttl}"
                  end
            Fluor.to_xmpp(
              slack.channels[message.channel].name,
              "fluor",
              Fluor.Slack.Utils.sanitize(msg, slack)
            )
          end)
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
  def handle_message(%{type: "presence_change",
                       user: user,
                       presence: presence}, slack, state) do
    try do
      case slack.users[user] do
        nil -> :noop
        u ->
          case presence do
            "active" -> Fluor.add_slack_user(u.name)
            "away" -> Fluor.remove_slack_user(u.name)
          end
      end
    catch
      e -> IO.inspect e
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
