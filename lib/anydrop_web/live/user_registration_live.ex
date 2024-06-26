defmodule AnydropWeb.UserRegistrationLive do
  use AnydropWeb, :live_view

  alias Anydrop.Accounts
  alias Anydrop.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header> Finish creating your account </.header>
      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/users/log_in?_action=registered"}
        method="post"
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input field={@form[:email]} type="email" label="Email" required readonly/>
        <.input field={@form[:username]} type="text" label="Username" required />
        <.input field={@form[:display_name]} type="text" label="Display Name" required />

        <:actions>
          <.button phx-disable-with="Creating account..." class="w-full">Create an account</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    email_from_flash = Phoenix.Flash.get(socket.assigns.flash, :email)
    email_from_token = Accounts.verify_registration_token(token)

    if email_from_flash == email_from_token do
      changeset = Accounts.change_user_registration(%User{}, %{email: email_from_flash})

      socket =
        socket
        |> assign(trigger_submit: false, check_errors: false)
        |> assign_form(changeset)

      {:ok, socket, temporary_assigns: [form: nil]}
    else
      {:ok, socket |> put_flash(:error, "Access Denied") |> redirect(to: ~p"/users/log_in")}
    end

  end

  def handle_event("save", %{"user" => user_params}, socket) do
    display_name = clean_display_name(user_params["display_name"])
    user_params = Map.put(user_params, "display_name", display_name)

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end

  defp clean_display_name(display_name) do
    display_name
      |> String.trim()
      |> String.replace(~r/\s+/, " ")
  end
end
