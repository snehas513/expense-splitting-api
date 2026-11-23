
import json
import streamlit as st
from api_client import APIError


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

        # Update profile name.
        st.divider()
        st.markdown("#### Update Profile")

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

                    st.session_state["success_message"] = (
                        "Profile updated successfully."
                    )
                    st.rerun()

                except APIError as exc:
                    show_error(exc)

        # Change email.
        st.divider()
        st.markdown("#### Change Email")

        st.caption(
            "A verification email will be sent to your new email address. "
            "Your current email remains unchanged until verification succeeds."
        )

        with st.form("change_email_form"):
            new_email = st.text_input(
                "New email address",
                key="new_email",
            )
            email_submitted = st.form_submit_button(
                "Send verification email"
            )

        if email_submitted:
            if not new_email.strip():
                st.error("Please enter a new email address.")
            else:
                try:
                    api.post(
                        "/api/v1/users/me/email_change",
                        {"new_email": new_email.strip()},
                    )
                    st.session_state["success_message"] = (
                        "Verification email sent. Please check your inbox."
                    )
                    st.rerun()

                except APIError as exc:
                    show_error(exc)

        # Deactivate account.
        st.divider()
        st.markdown("#### Deactivate Account")

        st.warning(
            "Deactivating your account will make it inactive and remove "
            "your active memberships from all groups. You cannot log in "
            "again while your account is deactivated."
        )

        if st.session_state.get("confirm_account_deactivation"):
            st.error(
                "Are you sure you want to deactivate your account?"
            )

            col1, col2 = st.columns(2)

            with col1:
                if st.button(
                    "Confirm deactivation",
                    key="confirm_deactivation",
                    type="primary",
                ):
                    try:
                        api.post("/api/v1/users/me/deactivate", {})

                        local_storage.deleteAll()

                        for key in (
                            "token",
                            "user",
                            "selected_group_id",
                            "group_memberships",
                            "confirm_account_deactivation",
                        ):
                            st.session_state.pop(key, None)

                        st.session_state["success_message"] = (
                            "Your account has been deactivated."
                        )
                        st.rerun()

                    except APIError as exc:
                        show_error(exc)

            with col2:
                if st.button(
                    "Cancel",
                    key="cancel_deactivation",
                ):
                    st.session_state.pop(
                        "confirm_account_deactivation",
                        None,
                    )
                    st.rerun()

        elif st.button(
            "Deactivate account",
            key="deactivate_account",
            type="secondary",
        ):
            st.session_state["confirm_account_deactivation"] = True
            st.rerun()

    except APIError as exc:
        show_error(exc)
