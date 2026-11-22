import streamlit as st
from api_client import APIError


def render(api, group_id, money, show_error):
    st.divider()
    st.subheader("Invitations")

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
                            st.session_state["success_message"] = "Invitation rejected."
                            st.rerun()
                        except APIError as exc:
                            show_error(exc)

    except APIError as exc:
        show_error(exc)
