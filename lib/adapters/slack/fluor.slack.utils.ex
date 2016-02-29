defmodule Fluor.Slack.Utils do
  def sanitize(string, slack) do
    string
    |> replace_emoji
    |> html_entities
    |> users(slack)
  end

  defp replace_emoji(string) do
    List.foldl(
      string |> list_emojis,
      string,
      fn {from, to}, acc ->
        String.replace acc, ":#{from}:", to
      end
    )
  end

  defp list_emojis(string) do

    in_string = Regex.scan(~r/:([^:]+):/,
                           string,
                           capture: :all_but_first) |> List.flatten
    List.foldl(
      in_string,
      [],
      fn emoji, acc ->
        to = case Exmoji.from_short_name emoji do
               nil -> parse_additional_emoji emoji
               actual_emoji -> Exmoji.unified_to_char actual_emoji.unified
             end
        IO.inspect emoji
        acc ++ [{emoji, to}]
      end
    )
  end

  defp parse_additional_emoji("simple_smile"), do: ":)"
  defp parse_additional_emoji("slightly_smiling_face"), do: ":|"
  defp parse_additional_emoji(emoji), do: ":#{emoji}:"


  defp html_entities(string) do
    string
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
  end

  defp users(string, slack) do
    in_string = Regex.scan(~r/<@([^>]+)>/,
                           string,
                           capture: :all_but_first) |> List.flatten
    users = slack.users
    List.foldl(
      in_string,
      string,
      fn user_id_like, acc ->
        user = case String.split(user_id_like, "|") do
                 [user_id|[]] ->
                   case users[user_id] do
                     nil -> "@#{user_id}"
                     user -> user.name
                   end
                 [_|[nick]] -> nick
               end
        String.replace acc, "<@#{user_id_like}>", user
      end
    )
  end
end
