
import streamlit as st
from api_client import APIError


def render(api, group_id, group, show_error):
    st.subheader("Group Management")

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

    st.write(f"**Group ID:** {group_id}")
    st.write(f"**Current group name:** {group.get('name', '—')}")

    # Admin-only management.
    if is_admin:
        st.divider()
        st.markdown("#### Update group name")

        with st.form("update_group_form"):
            updated_name = st.text_input(
                "Group name",
                value=group.get("name", ""),
            )

            submitted = st.form_submit_button(
                "Save changes",
                type="primary",
            )

        if submitted:
            if not updated_name.strip():
                st.error("Group name cannot be blank.")
            else:
                try:
                    api.patch(
                        f"/api/v1/groups/{group_id}",
                        {"name": updated_name.strip()},
                    )

                    st.session_state["success_message"] = (
                        "Group name updated successfully."
                    )
                    st.rerun()

                except APIError as exc:
                    show_error(exc)

        st.divider()
        st.markdown("#### Manage member roles")

        active_memberships = [
            membership
            for membership in memberships
            if membership.get("status") == "active"
        ]

        if not active_memberships:
            st.info("No active group members found.")
        else:
            for membership in active_memberships:
                member_user = membership.get("user") or {}
                user_id = member_user.get("id") or membership.get("user_id")
                name = member_user.get("name", "Unknown user")
                email = member_user.get("email", "")
                current_role = membership.get("role", "member")

                with st.container(border=True):
                    st.write(f"**{name}**")
                    st.caption(email)
                    st.write(f"Current role: **{current_role.title()}**")

                    if str(user_id) == str(current_user_id):
                        st.caption("You cannot change your own role.")
                        continue

                    if current_role not in ("admin", "member"):
                        st.caption("This role cannot be changed here.")
                        continue

                    new_role = (
                        "member" if current_role == "admin" else "admin"
                    )

                    action_label = (
                        "Demote to Member"
                        if current_role == "admin"
                        else "Promote to Admin"
                    )

                    if st.button(
                        action_label,
                        key=f"change_role_{membership.get('id')}",
                    ):
                        try:
                            api.patch(
                                f"/api/v1/groups/{group_id}/members/{user_id}/role",
                                {"role": new_role},
                            )

                            st.session_state["success_message"] = (
                                f"{name}'s role updated to {new_role.title()}."
                            )
                            st.rerun()

                        except APIError as exc:
                            show_error(exc)

        st.divider()
        st.markdown("#### Remove a member")

        removable_memberships = [
            membership
            for membership in active_memberships
            if str(
                membership.get("user_id")
                or (membership.get("user") or {}).get("id")
            ) != str(current_user_id)
        ]

        if not removable_memberships:
            st.info("There are no other active members to remove.")
        else:
            for membership in removable_memberships:
                member_user = membership.get("user") or {}
                user_id = member_user.get("id") or membership.get("user_id")
                name = member_user.get("name", "Unknown user")
                email = member_user.get("email", "")

                with st.container(border=True):
                    st.write(f"**{name}**")
                    st.caption(email)

                    pending_remove_id = st.session_state.get(
                        "pending_remove_user_id"
                    )

                    if str(pending_remove_id) == str(user_id):
                        st.warning(
                            f"Are you sure you want to remove {name} "
                            "from this group?"
                        )

                        col1, col2 = st.columns(2)

                        with col1:
                            if st.button(
                                "Confirm removal",
                                key=f"confirm_remove_{user_id}",
                                type="primary",
                            ):
                                try:
                                    api.delete(
                                        f"/api/v1/groups/{group_id}/members/{user_id}"
                                    )

                                    st.session_state.pop(
                                        "pending_remove_user_id", None
                                    )
                                    st.session_state["success_message"] = (
                                        f"{name} was removed from the group."
                                    )
                                    st.rerun()

                                except APIError as exc:
                                    show_error(exc)

                        with col2:
                            if st.button(
                                "Cancel",
                                key=f"cancel_remove_{user_id}",
                            ):
                                st.session_state.pop(
                                    "pending_remove_user_id", None
                                )
                                st.rerun()

                    elif st.button(
                        "Remove member",
                        key=f"remove_member_{user_id}",
                    ):
                        st.session_state["pending_remove_user_id"] = user_id
                        st.session_state["pending_leave_group"] = False
                        st.rerun()

        # Archive group.
        st.divider()
        st.markdown("#### Archive Group")

        st.warning(
            "Archiving this group will make it inactive. "
            "Make sure you really want to proceed."
        )

        if st.session_state.get("pending_archive_group"):
            st.error(
                f"Are you sure you want to archive "
                f"**{group.get('name', 'this group')}**?"
            )

            col1, col2 = st.columns(2)

            with col1:
                if st.button(
                    "Confirm archive",
                    key="confirm_archive_group",
                    type="primary",
                ):
                    try:
                        api.post(
                            f"/api/v1/groups/{group_id}/archive",
                            {},
                        )

                        st.session_state.pop(
                            "pending_archive_group", None
                        )
                        st.session_state.pop("selected_group_id", None)
                        st.session_state["success_message"] = (
                            f"{group.get('name', 'Group')} archived successfully."
                        )
                        st.rerun()

                    except APIError as exc:
                        show_error(exc)

            with col2:
                if st.button(
                    "Cancel",
                    key="cancel_archive_group",
                ):
                    st.session_state.pop(
                        "pending_archive_group", None
                    )
                    st.rerun()

        elif st.button(
            "Archive group",
            key="archive_group",
            type="secondary",
        ):
            st.session_state["pending_archive_group"] = True
            st.session_state.pop("pending_leave_group", None)
            st.session_state.pop("pending_remove_user_id", None)
            st.rerun()

    else:
        st.info("Only group admins can manage group settings and members.")

    # Leave group is available to every active member.
    if current_membership:
        st.divider()
        st.markdown("#### Leave group")

        st.write(
            "You can leave this group at any time, subject to the "
            "group's membership rules."
        )

        if st.session_state.get("pending_leave_group"):
            st.warning(
                f"Are you sure you want to leave **{group.get('name', 'this group')}**?"
            )

            col1, col2 = st.columns(2)

            with col1:
                if st.button(
                    "Confirm leave",
                    key="confirm_leave_group",
                    type="primary",
                ):
                    try:
                        api.post(
                            f"/api/v1/groups/{group_id}/leave",
                            {},
                        )

                        st.session_state.pop("pending_leave_group", None)
                        st.session_state["success_message"] = (
                            "You have left the group."
                        )
                        st.rerun()

                    except APIError as exc:
                        show_error(exc)

            with col2:
                if st.button("Cancel", key="cancel_leave_group"):
                    st.session_state.pop("pending_leave_group", None)
                    st.rerun()

        elif st.button("Leave group", key="leave_group"):
            st.session_state["pending_leave_group"] = True
            st.session_state.pop("pending_remove_user_id", None)
            st.rerun()
