
import streamlit as st

from api_client import APIError
from tabs.group_management import render


class FakeAPI:
    def __init__(self, patch_calls, post_calls, delete_calls):
        self.patch_calls = patch_calls
        self.post_calls = post_calls
        self.delete_calls = delete_calls

    def patch(self, path, payload):
        self.patch_calls.append({
            "path": path,
            "payload": payload,
        })

        if st.session_state.get("test_patch_error"):
            raise APIError("Update failed")

        return {"success": True}

    def post(self, path, payload):
        self.post_calls.append({
            "path": path,
            "payload": payload,
        })

        if st.session_state.get("test_post_error"):
            raise APIError("Request failed")

        return {"success": True}

    def delete(self, path):
        self.delete_calls.append(path)

        if st.session_state.get("test_delete_error"):
            raise APIError("Removal failed")

        return {"success": True}


def show_error(error):
    st.error(str(error))


if not st.session_state.get("_initialized"):
    st.session_state["user"] = {"id": 1}
    st.session_state["group_memberships"] = [
        {
            "id": 11,
            "user_id": 1,
            "user": {
                "id": 1,
                "name": "Alex",
                "email": "alex@example.com",
            },
            "role": "admin",
            "status": "active",
        },
        {
            "id": 12,
            "user_id": 2,
            "user": {
                "id": 2,
                "name": "Jane",
                "email": "jane@example.com",
            },
            "role": "member",
            "status": "active",
        },
    ]

    st.session_state["patch_calls"] = []
    st.session_state["post_calls"] = []
    st.session_state["delete_calls"] = []
    st.session_state["_initialized"] = True

api = FakeAPI(
    st.session_state["patch_calls"],
    st.session_state["post_calls"],
    st.session_state["delete_calls"],
)

render(
    api=api,
    group_id=1,
    group={"id": 1, "name": "Trip"},
    show_error=show_error,
)
