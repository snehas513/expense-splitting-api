
import streamlit as st

from tabs.members import render


class FakeAPI:
    def __init__(self, post_calls, get_calls):
        self.post_calls = post_calls
        self.get_calls = get_calls

    def get(self, path):
        self.get_calls.append(path)

        if path == "/api/v1/groups/1/inviteable_users":
            return {
                "users": [
                    {
                        "id": 3,
                        "name": "Sam",
                        "email": "sam@example.com",
                    }
                ]
            }

        return {}

    def post(self, path, payload):
        self.post_calls.append({
            "path": path,
            "payload": payload,
        })
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
    {
        "id": 12,
        "user_id": 2,
        "role": "member",
        "status": "active",
        "user": {
            "id": 2,
            "name": "Jane",
            "email": "jane@example.com",
        },
    },
    {
        "id": 13,
        "user_id": 4,
        "role": "member",
        "status": "inactive",
        "user": {
            "id": 4,
            "name": "Inactive User",
            "email": "inactive@example.com",
        },
    },
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
