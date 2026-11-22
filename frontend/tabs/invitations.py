
import streamlit as st
from api_client import APIError


def render(api, group_id, money, show_error):
    st.divider()
    st.subheader("Invitations")

    # Invitations received by the current user.
    st.markdown("#### Received Invitations")

    try:
        response = api.get("/api/v1/invitations")
        invitations = response.get("invitations", [])

        pending_invitations = [
            invitation
            for invitation in invitations
            if invitation.get("status") == "pending"
        ]

        if not pending_invitations:
            st.info("You don't have any pending invitations.")

        for invitation in pending_invitations:
            invitation_group = invitation.get("group") or {}
            inviter = invitation.get("invited_by") or {}
            invitation_id = invitation.get("id")
            invitation_group_id = invitation_group.get("id")

            with st.container(border=True):
                st.markdown(
                    f"**{invitation_group.get('name', 'Unknown group')}**"
                )
                st.write(
                    f"Invited by: {inviter.get('name', 'Unknown user')} "
                    f"({inviter.get('email', '')})"
                )
                st.caption(f"Sent at: {invitation.get('sent_at', '')}")

                accept_col, reject_col = st.columns(2)

                with accept_col:
                    if st.button(
                        "Accept",
                        key=f"accept_invitation_{invitation_id}",
                        type="primary",
                        use_container_width=True,
                    ):
                        try:
                            api.post(
                                f"/api/v1/groups/{invitation_group_id}/invitations/{invitation_id}/accept",
                                {},
                            )
                            st.session_state["success_message"] = (
                                f"You joined {invitation_group.get('name', 'the group')} successfully!"
                            )
                            st.rerun()
                        except APIError as exc:
                            show_error(exc)

                with reject_col:
                    if st.button(
                        "Reject",
                        key=f"reject_invitation_{invitation_id}",
                        use_container_width=True,
                    ):
                        try:
                            api.post(
                                f"/api/v1/groups/{invitation_group_id}/invitations/{invitation_id}/reject",
                                {},
                            )
                            st.session_state["success_message"] = (
                                "Invitation rejected."
                            )
                            st.rerun()
                        except APIError as exc:
                            show_error(exc)

    except APIError as exc:
        show_error(exc)

    # Sent invitations: admin-only functionality.
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
        st.divider()
        st.markdown("#### Sent Invitations")

        try:
            response = api.get(
                f"/api/v1/groups/{group_id}/invitations"
            )

            sent_invitations = response.get("invitations", [])

            pending_sent_invitations = [
                invitation
                for invitation in sent_invitations
                if invitation.get("status") == "pending"
            ]

            if not pending_sent_invitations:
                st.info("There are no pending invitations for this group.")

            for invitation in pending_sent_invitations:
                invitation_id = invitation.get("id")
                invited_user = invitation.get("invited_user") or {}

                name = invited_user.get("name", "Unknown user")
                email = invited_user.get("email", "")

                with st.container(border=True):
                    st.write(f"**{name}**")
                    st.caption(email)
                    st.caption(
                        f"Sent at: {invitation.get('sent_at', '')}"
                    )

                    pending_revoke_id = st.session_state.get(
                        "pending_revoke_invitation_id"
                    )

                    if str(pending_revoke_id) == str(invitation_id):
                        st.warning(
                            f"Are you sure you want to revoke the invitation "
                            f"sent to {name}?"
                        )

                        confirm_col, cancel_col = st.columns(2)

                        with confirm_col:
                            if st.button(
                                "Confirm revoke",
                                key=f"confirm_revoke_{invitation_id}",
                                type="primary",
                            ):
                                try:
                                    api.post(
                                        f"/api/v1/groups/{group_id}/invitations/{invitation_id}/revoke",
                                        {},
                                    )

                                    st.session_state.pop(
                                        "pending_revoke_invitation_id",
                                        None,
                                    )
                                    st.session_state["success_message"] = (
                                        f"Invitation to {name} revoked."
                                    )
                                    st.rerun()

                                except APIError as exc:
                                    show_error(exc)

                        with cancel_col:
                            if st.button(
                                "Cancel",
                                key=f"cancel_revoke_{invitation_id}",
                            ):
                                st.session_state.pop(
                                    "pending_revoke_invitation_id",
                                    None,
                                )
                                st.rerun()

                    elif st.button(
                        "Revoke invitation",
                        key=f"revoke_invitation_{invitation_id}",
                    ):
                        st.session_state[
                            "pending_revoke_invitation_id"
                        ] = invitation_id
                        st.rerun()

        except APIError as exc:
            show_error(exc)
