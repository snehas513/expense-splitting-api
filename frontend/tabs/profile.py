import streamlit as st
from api_client import APIError
import json


def render(api, group_id, money, show_error, local_storage):
    st.subheader("Your profile")

    try:
        profile_response = api.get("/api/v1/users/me")
        profile = profile_response.get("user", {})

        st.write(f"**Email:** {profile.get('email', '—')}")
        st.write(
            f"**Email verified:** "
            f"{'Yes' if profile.get('email_verified') else 'No'}"
        )
        st.write(f"**Account created:** {profile.get('created_at', '—')}")

        current_user_id = (st.session_state.get("user") or {}).get("id")
        memberships = st.session_state.get("group_memberships", [])

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

        role = (
            current_membership.get("role", "").title()
            if current_membership
            else "No active group membership"
        )

        st.write(f"**Role in selected group:** {role}")

        with st.form("update_profile_form"):
            updated_name = st.text_input(
                "Name",
                value=profile.get("name", ""),
                key="profile_name",
            )
            submitted = st.form_submit_button(
                "Save changes",
                type="primary",
            )

        if submitted:
            if not updated_name.strip():
                st.error("Name cannot be blank.")
            else:
                try:
                    update_response = api.patch(
                        "/api/v1/users/me",
                        {"name": updated_name.strip()},
                    )
                    updated_user = update_response.get("user", {})
                    if updated_user:
                        st.session_state["user"] = updated_user
                        local_storage.setItem(
                            "expense_splitter_user",
                            json.dumps(updated_user),
                            key="update_user_profile",
                        )
                    st.session_state["success_message"] = "Profile updated successfully."
                    st.rerun()
                except APIError as exc:
                    show_error(exc)

    except APIError as exc:
        show_error(exc)
