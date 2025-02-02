defmodule ChatWeb.ChatLive do
  use ChatWeb, :live_view
  alias Chat.Messages
  alias ChatWeb.Presence

  @topic "chat:lobby"

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Chat.PubSub, @topic)

      # プレゼンスへの参加
      {:ok, _} =
        Presence.track(self(), @topic, socket.assigns.current_user.id, %{
          user_id: socket.assigns.current_user.id,
          name: socket.assigns.current_user.email
        })
    end

    messages = Messages.list_messages()

    {:ok,
     socket
     |> stream(:messages, messages)
     |> assign(
       participants: [],
       current_message: ""
     ), temporary_assigns: [messages: []]}
  end

  @impl true
  def handle_event("send_message", %{"message" => message}, socket) do
    user = socket.assigns.current_user

    with {:ok, message} <-
           Messages.create_message(%{content: message, user_id: user.id}) do
      message = %{message | user: user}
      Phoenix.PubSub.broadcast(Chat.PubSub, @topic, {:new_message, message})
      {:noreply, assign(socket, current_message: "")}
    else
      {:error, _changeset} ->
        IO.inspect(_changeset)
        {:noreply, put_flash(socket, :error, "メッセージを送信できませんでした")}

      others ->
        IO.puts(others)
        {:noreply, put_flash(socket, :error, "メッセージを送信できませんでした")}
    end
  end

  @impl true
  def handle_event("message_changed", %{"message" => message}, socket) do
    {:noreply, assign(socket, current_message: message)}
  end

  @impl true
  def handle_event(_others, params, socket) do
    IO.inspect(params)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    participants =
      Presence.list(@topic)
      |> Enum.map(fn {_user_id, data} ->
        data[:metas]
        |> List.first()
      end)

    {:noreply, assign(socket, participants: participants)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen">
      <!-- 左サイドバー：参加者リスト -->
      <div class="w-64 bg-gray-100 border-r">
        <div class="p-4">
          <h2 class="font-bold mb-4">参加者</h2>
          <ul>
            <%= for participant <- @participants do %>
              <li class="py-2">{participant.name}</li>
            <% end %>
          </ul>
        </div>
      </div>
      
    <!-- 右メインエリア -->
      <div class="flex-1 flex flex-col">
        <!-- メッセージリスト -->
        <div class="flex-1 overflow-y-auto p-4">
          <div id="messages" phx-update="stream">
            <%= for {id, message} <- @streams.messages do %>
              <div class="mb-4" id={id}>
                <p class="font-bold">{message.user.email}</p>
                <p>{message.content}</p>
                <p class="text-xs text-gray-500">
                  {Calendar.strftime(message.inserted_at, "%Y-%m-%d %H:%M:%S")}
                </p>
              </div>
            <% end %>
          </div>
        </div>
        
    <!-- 入力フォーム -->
        <div class="border-t p-4">
          <form phx-submit="send_message" class="flex">
            <input
              type="text"
              name="message"
              value={@current_message}
              placeholder="メッセージを入力..."
              class="flex-1 rounded-l border p-2"
              phx-keyup="message_changed"
            />
            <button type="submit" class="bg-blue-500 text-white px-4 py-2 rounded-r">
              送信
            </button>
          </form>
        </div>
      </div>
    </div>
    """
  end
end
