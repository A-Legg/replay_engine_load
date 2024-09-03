defmodule ReplayEngineLoad.ClientPayloads do
  def join_topic(topic, user_id) do
    %{
      "topic" => topic,
      "event" => "phx_join",
      "payload" => %{"user_id" => user_id},
      "ref" => "1",
      "join_ref" => "1"
    }
  end

  def new_matchup(league, type) do
    %{
      "topic" => "matchups",
      "event" => "new_matchup",
      "payload" => %{"league" => league, "type" => type},
      "ref" => "1",
      "join_ref" => "1"
    }
  end

  def transition_matchup do
    %{
      "topic" => "matchups",
      "event" => "transition_matchup",
      "payload" => %{},
      "ref" => "1",
      "join_ref" => "1"
    }
  end
end
