
import streamlit as st
from api_client import APIError
from decimal import Decimal


def get_settlement_permissions(
    current_user_id,
    sender_id,
    receiver_id,
    creator_id,
):
    is_creator = str(current_user_id) == str(creator_id)

    is_other_party = (
        str(current_user_id) in {
            str(sender_id),
            str(receiver_id),
        }
        and not is_creator
    )

    return {
        "can_cancel": is_creator,
        "can_respond": is_other_party,
    }


def render(api, group_id, money, show_error):
    st.markdown("#### Create settlement")

    memberships = st.session_state.get("group_memberships", [])
    expenses = st.session_state.get("group_expenses", [])

    member_options = {}

    for membership in memberships:
        if membership.get("status") != "active":
            continue

        user = membership.get("user") or {}
        user_id = user.get("id") or membership.get("user_id")

        if user_id:
            name = user.get("name", "Unknown")
            email = user.get("email", "")
            member_options[user_id] = f"{name} ({email})"

    expense_options = {
        expense["id"]: (
            f'{expense.get("description", "Expense")} · '
            f'{money(expense.get("amount"))} · '
            f'ID: {expense["id"]}'
        )
        for expense in expenses
        if expense.get("id") is not None
    }

    form_version = st.session_state.get("settlement_form_version", 0)

    if not member_options:
        st.info("No active group members available.")

    elif not expense_options:
        st.info("No expenses available for settlement.")

    else:
        st.markdown("**Settlement details**")

        selected_expense_ids = st.multiselect(
            "Expenses to settle",
            options=list(expense_options.keys()),
            format_func=lambda expense_id: expense_options[expense_id],
            key=f"settlement_expenses_{form_version}",
        )

        if selected_expense_ids:
            with st.form(f"create_settlement_form_{form_version}"):

                sender_id = st.selectbox(
                    "Sender (who owes money)",
                    options=list(member_options.keys()),
                    format_func=lambda user_id: member_options[user_id],
                )

                receiver_id = st.selectbox(
                    "Receiver (who receives money)",
                    options=list(member_options.keys()),
                    format_func=lambda user_id: member_options[user_id],
                )

                st.markdown("**Expense allocations**")

                allocation_amounts = {}

                for expense_id in selected_expense_ids:
                    allocation_amounts[expense_id] = st.number_input(
                        expense_options[expense_id],
                        min_value=0.0,
                        step=0.01,
                        format="%.2f",
                        key=f"allocation_{form_version}_{expense_id}",
                    )

                settlement_date = st.date_input("Settlement date")
                note = st.text_area("Note (optional)")

                submitted = st.form_submit_button(
                    "Create settlement",
                    type="primary",
                )

            if submitted:
                if sender_id == receiver_id:
                    st.error("Sender and receiver must be different.")

                elif any(amount <= 0 for amount in allocation_amounts.values()):
                    st.error("Every expense allocation must be greater than zero.")

                else:
                    total_amount = sum(
                        (Decimal(str(amount)) for amount in allocation_amounts.values()),
                        Decimal("0.00"),
                    )

                    payload = {
                        "sender_id": sender_id,
                        "receiver_id": receiver_id,
                        "settlement_amount": f"{total_amount:.2f}",
                        "settlement_date": settlement_date.isoformat(),
                        "allocations": [
                            {
                                "expense_id": expense_id,
                                "allocation_amount": f"{Decimal(str(amount)):.2f}",
                            }
                            for expense_id, amount in allocation_amounts.items()
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
                                "Settlement created successfully."
                            )
                            st.session_state["settlement_form_version"] = (
                                form_version + 1
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

        else:
            st.info("Select at least one expense to allocate.")

    st.divider()
    st.markdown("#### Settlement history")

    status_options = ["All", "pending", "confirmed", "rejected", "cancelled"]
    selected_status = st.selectbox(
        "Filter by status",
        status_options,
        key="settlement_status_filter",
    )

    try:
        limit = 20
        params = f"limit={limit}"

        if selected_status != "All":
            params += f"&status={selected_status}"

        response = api.get(
            f"/api/v1/groups/{group_id}/settlements?{params}"
        )
        settlements = response.get("settlements", [])

        if settlements:
            current_user_id = (st.session_state.get("user") or {}).get("id")

            for settlement in settlements:
                sender = settlement.get("sender") or {}
                receiver = settlement.get("receiver") or {}
                creator = (
                    settlement.get("creator")
                    or settlement.get("created_by")
                    or {}
                )

                status = settlement.get("status") or "unknown"
                settlement_id = settlement.get("id")

                permissions = get_settlement_permissions(
                    current_user_id=current_user_id,
                    sender_id=sender.get("id"),
                    receiver_id=receiver.get("id"),
                    creator_id=creator.get("id"),
                )

                with st.expander(
                    f'{sender.get("name", "—")} → '
                    f'{receiver.get("name", "—")} · '
                    f'{money(settlement.get("settlement_amount"))} · '
                    f'{status.upper()}'
                ):
                    st.write(
                        f'**Date:** {settlement.get("settlement_date", "—")}'
                    )
                    st.write(
                        f'**Created by:** {creator.get("name", "—")}'
                    )
                    st.write(f'**Note:** {settlement.get("note") or "—"}')

                    actor = settlement.get("acted_by") or {}
                    st.write(f'**Last action by:** {actor.get("name", "—")}')

                    # The other party can confirm or reject a pending settlement.
                    if status == "pending" and permissions["can_respond"]:
                        st.divider()
                        st.write("**Respond to settlement request**")

                        col1, col2 = st.columns(2)

                        with col1:
                            if st.button(
                                "Confirm",
                                key=f"confirm_settlement_{settlement_id}",
                                type="primary",
                                use_container_width=True,
                            ):
                                try:
                                    action_response = api.post(
                                        f"/api/v1/groups/{group_id}/settlements/{settlement_id}/confirm",
                                        {},
                                    )

                                    if action_response.get("success"):
                                        st.session_state["success_message"] = (
                                            "Settlement confirmed successfully."
                                        )
                                        st.rerun()
                                    else:
                                        st.error(
                                            action_response.get(
                                                "errors",
                                                "Could not confirm settlement.",
                                            )
                                        )

                                except APIError as exc:
                                    show_error(exc)

                        with col2:
                            if st.button(
                                "Reject",
                                key=f"reject_settlement_{settlement_id}",
                                use_container_width=True,
                            ):
                                try:
                                    action_response = api.post(
                                        f"/api/v1/groups/{group_id}/settlements/{settlement_id}/reject",
                                        {},
                                    )

                                    if action_response.get("success"):
                                        st.session_state["success_message"] = (
                                            "Settlement rejected successfully."
                                        )
                                        st.rerun()
                                    else:
                                        st.error(
                                            action_response.get(
                                                "errors",
                                                "Could not reject settlement.",
                                            )
                                        )

                                except APIError as exc:
                                    show_error(exc)

                    # Only the creator can cancel a pending settlement.
                    if status == "pending" and permissions["can_cancel"]:
                        st.divider()

                        if st.button(
                            "Cancel settlement",
                            key=f"cancel_settlement_{settlement_id}",
                            use_container_width=True,
                        ):
                            try:
                                action_response = api.post(
                                    f"/api/v1/groups/{group_id}/settlements/{settlement_id}/cancel",
                                    {},
                                )

                                if action_response.get("success"):
                                    st.session_state["success_message"] = (
                                        "Settlement cancelled successfully."
                                    )
                                    st.rerun()
                                else:
                                    st.error(
                                        action_response.get(
                                            "errors",
                                            "Could not cancel settlement.",
                                        )
                                    )

                            except APIError as exc:
                                show_error(exc)

        else:
            st.info("No settlements found.")

        pagination = response.get("pagination") or {}
        if pagination.get("has_more"):
            st.caption(
                "More settlements are available. Cursor pagination "
                "can be added to the UI in the next iteration."
            )

    except APIError as exc:
        show_error(exc)
