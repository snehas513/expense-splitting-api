
import streamlit as st
from decimal import Decimal, InvalidOperation

from api_client import APIError


def to_decimal(value):
    try:
        return Decimal(str(value or "0"))
    except (InvalidOperation, TypeError, ValueError):
        return Decimal("0")


def render(api, group_id, money, show_error):
    st.markdown("#### Group balances")

    # Group-wide balance summary.
    try:
        balances = api.get(
            f"/api/v1/groups/{group_id}/balances"
        ).get("balances", [])

        if balances:
            for item in balances:
                amount = float(item.get("balance", 0))
                label = (
                    "is owed"
                    if amount > 0
                    else "owes"
                    if amount < 0
                    else "settled"
                )

                st.write(
                    f'**{item.get("name", "Member")}** '
                    f'{label} **{money(abs(amount))}**'
                )

            st.caption(
                "Positive balances are receivable; "
                "negative balances are payable."
            )
        else:
            st.info("No balances found.")

    except APIError as exc:
        show_error(exc)
        return

    # Identify other group members.
    current_user_id = (
        st.session_state.get("user") or {}
    ).get("id")

    other_members = {
        item["user_id"]: item.get("name", "Member")
        for item in balances
        if item.get("user_id") is not None
        and str(item["user_id"]) != str(current_user_id)
    }

    if not other_members:
        return

    st.divider()
    st.markdown("#### Balances with members")

    member_labels = {
        f"{name} (ID: {user_id})": user_id
        for user_id, name in other_members.items()
    }

    selected_label = st.selectbox(
        "Select a member",
        options=list(member_labels.keys()),
        key=f"balance_member_{group_id}",
    )

    member_id = member_labels[selected_label]
    member_name = other_members[member_id]

    # Fetch pairwise balance and expense breakdown.
    try:
        response = api.get(
            f"/api/v1/groups/{group_id}/balances/{member_id}"
        )
        breakdown = response.get("breakdown", {})

    except APIError as exc:
        show_error(exc)
        return

    outstanding_debt = to_decimal(
        breakdown.get("outstanding_debt")
    )

    user_owes_member = breakdown.get("user_owes_member", [])
    member_owes_user = breakdown.get("member_owes_user", [])

    # Net balance.
    st.markdown("##### Net balance")

    if outstanding_debt > 0:
        st.metric(
            f"You owe {member_name}",
            money(float(outstanding_debt)),
        )
    else:
        st.metric("Net balance", money(0))
        st.caption(f"You're settled with {member_name}.")

    # Your share of expenses paid by the selected member.
    st.markdown(
        f"##### Your share of expenses paid by {member_name}"
    )
    st.caption(
        "These are expense-wise amounts before offsetting "
        "balances in the opposite direction."
    )

    if user_owes_member:
        for item in user_owes_member:
            expense = item.get("expense", {})

            st.write(
                f'**{expense.get("description", "Expense")}**'
            )

            col1, col2, col3 = st.columns(3)

            col1.write(
                f'**Share:** {money(float(to_decimal(item.get("share_amount"))))}'
            )
            col2.write(
                f'**Allocated:** {money(float(to_decimal(item.get("allocated_amount"))))}'
            )
            col3.write(
                f'**Remaining:** {money(float(to_decimal(item.get("remaining_amount"))))}'
            )

    else:
        st.info("No outstanding expenses in this direction.")

    # Selected member's share of expenses paid by current user.
    st.markdown(
        f"##### {member_name}'s share of expenses paid by you"
    )
    st.caption(
        "These are expense-wise amounts before offsetting "
        "balances in the opposite direction."
    )

    if member_owes_user:
        for item in member_owes_user:
            expense = item.get("expense", {})

            st.write(
                f'**{expense.get("description", "Expense")}**'
            )

            col1, col2, col3 = st.columns(3)

            col1.write(
                f'**Share:** {money(float(to_decimal(item.get("share_amount"))))}'
            )
            col2.write(
                f'**Allocated:** {money(float(to_decimal(item.get("allocated_amount"))))}'
            )
            col3.write(
                f'**Remaining:** {money(float(to_decimal(item.get("remaining_amount"))))}'
            )

    else:
        st.info("No outstanding expenses in this direction.")

    # Settlement creation.
    # Only show this when the current user owes the selected member.
    if outstanding_debt <= 0 or not user_owes_member:
        return

    st.divider()
    st.markdown("#### Create settlement")

    expense_options = {}

    for item in user_owes_member:
        expense = item.get("expense", {})
        expense_id = expense.get("id")
        remaining = to_decimal(item.get("remaining_amount"))

        if expense_id is None or remaining <= 0:
            continue

        description = expense.get("description", "Expense")
        expense_date = expense.get("expense_date", "")

        label = (
            f"{description} · {expense_date} · "
            f"Remaining: {money(float(remaining))}"
        )

        expense_options[label] = item

    if not expense_options:
        st.info("No remaining expense amounts available for settlement.")
        return

    selected_expenses = st.multiselect(
        "Select expenses to allocate the settlement against",
        options=list(expense_options.keys()),
        key=f"settlement_expenses_{group_id}_{member_id}",
    )

    if not selected_expenses:
        st.info("Select at least one expense to continue.")
        return

    selected_items = [
        expense_options[label]
        for label in selected_expenses
    ]

    available_total = sum(
        (
            to_decimal(item.get("remaining_amount"))
            for item in selected_items
        ),
        Decimal("0"),
    )

    if available_total < outstanding_debt:
        st.warning(
            "The selected expenses do not have enough remaining amount "
            "to cover the net outstanding debt. Select more expenses."
        )

    # Allocate the net debt across selected expenses.
    remaining_budget = outstanding_debt
    default_allocations = []

    for item in selected_items:
        expense_remaining = to_decimal(
            item.get("remaining_amount")
        )

        allocation = min(expense_remaining, remaining_budget)

        default_allocations.append(allocation)
        remaining_budget -= allocation

    # Include selection in widget keys so changed selections
    # receive freshly calculated default allocations.
    selection_signature = "_".join(
        sorted(
            str(item.get("expense", {}).get("id"))
            for item in selected_items
        )
    )

    with st.form(f"create_settlement_{group_id}_{member_id}"):

        st.write(
            f"**Net outstanding debt:** "
            f"{money(float(outstanding_debt))}"
        )

        allocations = []

        for index, item in enumerate(selected_items):
            expense = item.get("expense", {})
            expense_id = expense.get("id")

            expense_remaining = to_decimal(
                item.get("remaining_amount")
            )

            default_amount = default_allocations[index]

            amount = st.number_input(
                (
                    f'{expense.get("description", "Expense")} '
                    f'(Remaining: {money(float(expense_remaining))})'
                ),
                min_value=0.0,
                max_value=float(expense_remaining),
                value=float(default_amount),
                step=0.01,
                format="%.2f",
                key=(
                    f"allocation_{group_id}_{member_id}_"
                    f"{selection_signature}_{expense_id}"
                ),
            )

            allocations.append({
                "expense_id": expense_id,
                "allocation_amount": to_decimal(amount),
            })

        settlement_date = st.date_input("Settlement date")
        note = st.text_input("Note (optional)")

        total_amount = sum(
            (
                item["allocation_amount"]
                for item in allocations
            ),
            Decimal("0"),
        )

        st.write(
            f"**Allocation total:** {money(float(total_amount))}"
        )

        submitted = st.form_submit_button(
            "Create settlement",
            type="primary",
            disabled=available_total < outstanding_debt,
        )

    if submitted:
        if total_amount <= 0:
            st.error("Settlement amount must be greater than zero.")
            return

        if total_amount != outstanding_debt:
            st.error(
                "The allocation total must equal the net outstanding "
                f"debt of {money(float(outstanding_debt))}."
            )
            return

        if any(
            item["allocation_amount"] <= 0
            for item in allocations
        ):
            st.error("Every expense allocation must be greater than zero.")
            return

        payload = {
            "sender_id": current_user_id,
            "receiver_id": member_id,
            "settlement_amount": f"{total_amount:.2f}",
            "settlement_date": settlement_date.isoformat(),
            "allocations": [
                {
                    "expense_id": item["expense_id"],
                    "allocation_amount": (
                        f'{item["allocation_amount"]:.2f}'
                    ),
                }
                for item in allocations
            ],
            "note": note.strip(),
        }

        try:
            response = api.post(
                f"/api/v1/groups/{group_id}/settlements",
                payload,
            )

            if response.get("success"):
                st.session_state["success_message"] = (
                    "Settlement request created successfully."
                )
                st.rerun()
            else:
                st.error(
                    response.get(
                        "errors",
                        "Could not create settlement.",
                    )
                )

        except APIError as exc:
            show_error(exc)
