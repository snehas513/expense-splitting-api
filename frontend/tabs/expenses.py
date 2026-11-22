import streamlit as st
from api_client import APIError


def render(api, group_id, money, show_error):
    st.markdown("#### Create expense")

    memberships = st.session_state.get("group_memberships", [])

    # Build a list of active group members
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

    if not member_options:
        st.info("No active group members available.")
    else:
        form_version = st.session_state.get("expense_form_version", 0)

        with st.form(f"create_expense_form_{form_version}"):
            description = st.text_input("Description")

            amount = st.number_input(
                "Amount (₹)",
                min_value=0.01,
                step=0.01,
                format="%.2f",
            )

            payer_id = st.selectbox(
                "Paid by",
                options=list(member_options.keys()),
                format_func=lambda user_id: member_options[user_id],
            )

            participant_ids = st.multiselect(
                "Participants",
                options=list(member_options.keys()),
                format_func=lambda user_id: member_options[user_id],
            )

            expense_date = st.date_input("Expense date")

            note = st.text_area("Note (optional)")

            submitted = st.form_submit_button(
                "Create expense",
                type="primary",
            )

        if submitted:
            if not description.strip():
                st.error("Description cannot be blank.")

            elif not participant_ids:
                st.error("Select at least one participant.")

            else:
                payload = {
                    "payer_id": payer_id,
                    "participant_ids": participant_ids,
                    "amount": f"{amount:.2f}",
                    "description": description.strip(),
                    "expense_date": expense_date.isoformat(),
                    "note": note.strip(),
                }

                try:
                    response = api.post(
                        f"/api/v1/groups/{group_id}/expenses",
                        payload,
                    )

                    if response.get("success"):
                        st.session_state["success_message"] = (
                            "Expense created successfully."
                        )
                        st.session_state["expense_form_version"] = (
                            form_version + 1
                        )
                        st.rerun()
                    else:
                        st.error(
                            response.get("errors", "Could not create expense.")
                        )

                except APIError as exc:
                    show_error(exc)

    st.divider()
    st.markdown("#### Expense history")

    try:
        limit = 20
        response = api.get(
            f"/api/v1/groups/{group_id}/expenses?limit={limit}"
        )
        expenses = response.get("expenses", [])
        st.session_state["group_expenses"] = expenses

        if expenses:
            for expense in expenses:
                payer = expense.get("payer") or {}
                participants = expense.get("participants") or []

                with st.expander(
                    f'{expense.get("description", "Expense")} · '
                    f'{money(expense.get("amount"))}'
                ):
                    left, right = st.columns(2)
                    left.write(f'**Paid by:** {payer.get("name", "—")}')
                    right.write(f'**Date:** {expense.get("expense_date", "—")}')

                    st.write("**Participant shares**")

                    share_rows = []
                    for participant in participants:
                        user = participant.get("user") or {}
                        share_rows.append({
                            "Participant": user.get("name"),
                            "Share": money(participant.get("share_amount")),
                        })

                    st.dataframe(
                        share_rows,
                        use_container_width=True,
                        hide_index=True,
                    )
        else:
            st.info("No expenses found.")

        pagination = response.get("pagination") or {}
        if pagination.get("has_more"):
            st.caption(
                "More expenses are available. Cursor pagination can be "
                "added to the UI in the next iteration."
            )

    except APIError as exc:
        show_error(exc)
