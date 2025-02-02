defmodule Chat.Messages do
  import Ecto.Query
  alias Chat.Repo
  alias Chat.Messages.Message

  def list_messages do
    Message
    |> order_by([m], asc: m.inserted_at)
    |> preload(:user)
    |> Repo.all()
  end

  def create_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end
end
