defmodule Fluor.Slack do
  use Slack

  def handle_connect(slack, state) do
    #IO.puts "Connected as #{slack.me.name}"
    #IO.inspect slack
    #IO.inspect state
    {:ok, state}
  end

  def handle_message(message = %{type: "message"}, slack, state) do
    #message_to_send = "Received #{length(state)} messages so far!"
    #IO.inspect message
    #IO.inspect slack.channels #(slack.channels |> Map.fetch(message.channel))
    #send_message("woop", message.channel, slack)

    #IO.inspect slack.users
    #IO.inspect slack.users[message.user].

    #IO.inspect :sub_type in message
    #IO.inspect slack.channels[message.channel]
    #IO.inspect slack.users[message.user]
    #IO.inspect user.name
    

    case :sub_type in message do
      false ->
        case slack.channels[message.channel] do
          nil -> :noop
          channel ->
            case slack.users[message.user] do
              nil -> :noop
              user ->
                case user.name do
                  "fluor" -> :noop
                  name ->
                    #IO.inspect "Got message in #{channel.name}: #{message.text} from #{name}"
                    Fluor.to_xmpp channel.name, name, message.text
                end
            end
        end
      _ -> :noop
    end
    {:ok, state}
  end

  def handle_message(_message, _slack, state) do
    {:ok, state}
  end

  def handle_info({:say, message, channel_name}, slack, state) do
    #IO.inspect "channel fetch"
    #IO.inspect channel_name
    channel_id = slack.channels |> Map.values
    |> Enum.find(fn(channel) -> channel.name == channel_name end)
    |> Map.get(:id)

    #channel_id = slack.channels
    #|> Map.values
    #|> Enum.find(fn(channel) -> channel.name == channel_name end)
    #|> Map.get(:id)

    #IO.inspect "channel is #{channel_id}"

    send_message(message, channel_id, slack)
    {:ok, state}
  end
  def handle_info(_message, _slack, state), do: {:ok, state}

end
