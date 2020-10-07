defmodule ChatApiWeb.BillingController do
  use ChatApiWeb, :controller

  alias ChatApi.{Accounts, Billing}

  action_fallback ChatApiWeb.FallbackController

  def show(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         account <- Accounts.get_account!(account_id),
         billing_info <- Billing.get_billing_info(account) do
      render(conn, "show.json", billing_info: billing_info)
    end
  end

  def create(conn, %{"plan" => plan}) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         account <- Accounts.get_account!(account_id),
         {:ok, _account} <- Billing.create_subscription_plan(account, plan) do
      notify_slack(conn)
      json(conn, %{data: %{ok: true}})
    end
  end

  def update(conn, %{"plan" => plan}) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         account <- Accounts.get_account!(account_id),
         {:ok, _account} <- Billing.update_subscription_plan(account, plan) do
      notify_slack(conn)
      json(conn, %{data: %{ok: true}})
    end
  end

  @spec notify_slack(Conn.t()) :: Conn.t()
  defp notify_slack(conn) do
    with %{email: email, plan: plan} <- conn.assigns.current_user do
      # Putting in an async Task for now, since we don't care if this succeeds
      # or fails (and we also don't want it to block anything)
      Task.start(fn ->
        ChatApi.Slack.log("#{email} set subscription plan to #{plan}")
      end)
    end

    conn
  end
end
