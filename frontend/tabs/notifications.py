import streamlit as st
from api_client import APIError


def render(api, group_id, money, show_error):
    st.markdown("#### Notifications")
    try:
        notifications = api.get("/api/v1/notifications").get("notifications", [])
        if notifications:
            for notification in notifications:
                col1, col2 = st.columns([5, 1])
                with col1:
                    st.write(notification.get("message", "Notification"))
                    st.caption(f'{notification.get("notification_type")} · {notification.get("created_at")}')
                with col2:
                    if not notification.get("read"):
                        if st.button("Mark read", key=f'read_{notification.get("id")}'):
                            try:
                                api.patch(f'/api/v1/notifications/{notification.get("id")}/mark_as_read', {})
                                st.rerun()
                            except APIError as exc:
                                show_error(exc)
                st.divider()
        else:
            st.info("No unread notifications.")
    except APIError as exc:
        show_error(exc)
