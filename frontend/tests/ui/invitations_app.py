import streamlit as st

from tabs.invitations import render


class FakeAPI:
    def __init__(self, post_calls, get_calls):
        self.post_calls = post_calls
        self.get_calls = get_calls

    def get(self, path):
        self.get_calls.append(path)

        if path == "/api/v1/invitations":
            return {
                "invitations": st.session_state["received_invitations"]
            }

        if path == "/api/v1/groups/1/invitations":
            return {
                "invitations": st.session_state["sent_invitations"]
            }

        return {}

    def post(self, path, payload):
        self.post_calls.append({
            "path": path,
            "payload": payload,
        })

        if path.endswith("/accept"):
            st.session_state["received_invitations"][0]["status"] = "accepted"
        elif path.endswith("/reject"):
            st.session_state["received_invitations"][0]["status"] = "rejected"
        elif path.endswith("/revoke"):
            st.session_state["sent_invitations"][0]["status"] = "revoked"

        return {"success": True}


def money(amount):
    return f"₹{float(amount):,.2f}"


def show_error(error):
    st.error(str(error))


role = st.session_state.get("test_role", "admin")

st.session_state["user"] = {"id": 1}
st.session_state["group_memberships"] = [
    {
        "id": 11,
        "user_id": 1,
        "role": role,
        "status": "active",
        "user": {
            "id": 1,
            "name": "Alex",
            "email": "alex@example.com",
        },
    },
]

if "received_invitations" not in st.session_state:
    st.session_state["received_invitations"] = [
        {
            "id": 101,
            "status": "pending",
            "sent_at": "2026-11-23",
            "group": {
                "id": 2,
                "name": "Trip Group",
            },
            "invited_by": {
                "name": "Jane",
                "email": "jane@example.com",
            },
        }
    ]

if "sent_invitations" not in st.session_state:
    st.session_state["sent_invitations"] = [
        {
            "id": 201,
            "status": "pending",
            "sent_at": "2026-11-23",
            "invited_user": {
                "id": 3,
                "name": "Sam",
                "email": "sam@example.com",
            },
        }
    ]

if "post_calls" not in st.session_state:
    st.session_state["post_calls"] = []

if "get_calls" not in st.session_state:
    st.session_state["get_calls"] = []

api = FakeAPI(
    st.session_state["post_calls"],
    st.session_state["get_calls"],
)

render(
    api=api,
    group_id=1,
    money=money,
    show_error=show_error,
)