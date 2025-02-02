defmodule Chat.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "messages" do
    field :content, :string
    belongs_to :user, Chat.Accounts.User, type: :binary_id

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :user_id])
    |> validate_required([:content, :user_id])
  end
end
