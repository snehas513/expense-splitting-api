
import streamlit as st
from api_client import APIError


def render(api, group_id, money, show_error):
    st.divider()

    # Reuse memberships loaded by app.py.
    memberships = st.session_state.get("group_memberships", [])

    current_user_id = (st.session_state.get("user") or {}).get("id")
    current_membership = next(
        (
            membership
            for membership in memberships
            if str(
                membership.get("user_id")
                or (membership.get("user") or {}).get("id")
            ) == str(current_user_id)
            and membership.get("status") == "active"
        ),
        None,
    )

    is_admin = (
        current_membership is not None
        and current_membership.get("role") == "admin"
    )

    if is_admin:
        with st.expander("Invite a member"):
            try:
                response = api.get(
                    f"/api/v1/groups/{group_id}/inviteable_users"
                )
                inviteable_users = response.get("users", [])

                if inviteable_users:
                    user_options = {
                        f"{user.get('name', 'User')} ({user.get('email', '')})": user
                        for user in inviteable_users
                    }

                    with st.form("invite_member_form"):
                        selected_user_label = st.selectbox(
                            "Select a user to invite",
                            options=list(user_options.keys()),
                        )
                        submitted = st.form_submit_button(
                            "Send Invitation",
                            type="primary",
                        )

                    if submitted:
                        selected_user = user_options[selected_user_label]

                        try:
                            api.post(
                                f"/api/v1/groups/{group_id}/invitations",
                                {"invited_user_id": selected_user["id"]},
                            )
                            st.session_state["success_message"] = (
                                f"Invitation sent to "
                                f"{selected_user.get('name', 'user')}."
                            )
                            st.rerun()
                        except APIError as exc:
                            show_error(exc)

                else:
                    st.info("No users available to invite.")

            except APIError as exc:
                show_error(exc)

    st.markdown("#### Group members")

    active_memberships = [
        membership
        for membership in memberships
        if membership.get("status") == "active"
    ]

    if active_memberships:
        rows = []

        for membership in active_memberships:
            member_user = membership.get("user") or {}

            rows.append({
                "User ID": member_user.get("id"),
                "Name": member_user.get("name"),
                "Email": member_user.get("email"),
                "Role": membership.get("role"),
                "Status": membership.get("status"),
                "Membership ID": membership.get("id"),
            })

        st.dataframe(rows, use_container_width=True, hide_index=True)
    else:
        st.info("No active group members found.")
