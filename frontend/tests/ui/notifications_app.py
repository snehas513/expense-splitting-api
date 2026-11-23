import streamlit as st

from tabs.notifications import render


class FakeAPI:
    def __init__(self, patch_calls):
        self.patch_calls = patch_calls

    def get(self, path):
        if path == "/api/v1/notifications":
            return {
                "notifications": st.session_state["notifications"]
            }
        return {}

    def patch(self, path, payload):
        self.patch_calls.append({
            "path": path,
            "payload": payload,
        })

        notification_id = int(path.split("/")[-2])

        for notification in st.session_state["notifications"]:
            if notification["id"] == notification_id:
                notification["read"] = True

        return {"success": True}


def money(amount):
    return f"₹{float(amount):,.2f}"


def show_error(error):
    st.error(str(error))


if "notifications" not in st.session_state:
    st.session_state["notifications"] = [
        {
            "id": 101,
            "message": "Jane invited you to Trip Group.",
            "notification_type": "group_invitation",
            "created_at": "2026-11-23",
            "read": False,
        },
        {
            "id": 102,
            "message": "Your settlement was confirmed.",
            "notification_type": "settlement_confirmation",
            "created_at": "2026-11-22",
            "read": True,
        },
    ]

if "patch_calls" not in st.session_state:
    st.session_state["patch_calls"] = []

api = FakeAPI(st.session_state["patch_calls"])

render(
    api=api,
    group_id=1,
    money=money,
    show_error=show_error,
)