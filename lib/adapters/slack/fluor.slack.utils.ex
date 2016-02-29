defmodule Fluor.Slack.Utils do
  def sanitize(string) do
    string |> replace_emoji
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
               nil -> ":#{emoji}:"
               actual_emoji -> Exmoji.unified_to_char actual_emoji.unified
             end
        IO.inspect emoji
        acc ++ [{emoji, to}]
      end
    )
  end
end
