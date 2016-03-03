defmodule Fluor.Slack do
  use Slack
  require Logger

  def handle_connect(_slack, state) do
    # Enum.each(slack.users, fn {_, %{name: name}} -> Fluor.add_slack_user(name) end)
    :lager.log(:debug, self,
               "Slack connected",
               []
    )
    {:ok, state}
  end

  def handle_message(message = %{type: "message"}, slack, state) do
    IO.inspect message
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
                        false ->
                          case message[:subtype] == "message_changed" do
                            true -> :nil
                            false -> img
                          end
                      end
                    false ->
                      txt = case text == nil do
                              true -> ""
                              false -> text |> String.slice(0, 100)
                            end
                      ttl = case title == nil do
                              true -> ""
                              false -> title
                            end
                      "#{ttl} | #{txt}"
                  end
            case msg do
              nil -> :noop
              _ ->
                Fluor.to_xmpp(
                  slack.channels[message.channel].name,
                  "fluor",
                  Fluor.Slack.Utils.sanitize(msg, slack)
                )
            end
          end)
      end
    rescue
      e in _ ->
        :lager.log(:error, self,
                   "Slack message outgoing. error: ~p",
                   [e]
        )
    catch
      e ->
        :lager.log(:error, self,
                   "Slack message outgoing. error: ~p",
                   [e]
        )
    end
    {:ok, state}
  end
  def handle_message(%{type: "presence_change",
                       user: user,
                       presence: presence}, slack, state) do
    :lager.log(:debug, self,
               "Slack presence change. user: ~p, presence: ~p",
               [user, presence]
    )

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
      e ->
        :lager.log(:error, self,
                   "Slack presence change. error: ~p",
                   [e]
        )
    end
    {:ok, state}
  end

  def handle_message(message, _slack, state) do
    :lager.log(:debug, self,
               "Slack other message. message: ~p",
               [message]
    )
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
  def handle_info(message, _slack, state) do
    :lager.log(:debug, self,
               "Slack other info. info: ~p",
               [message]
    )
    {:ok, state}
  end

end
