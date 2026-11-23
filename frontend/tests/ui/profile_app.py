import json
import streamlit as st

from api_client import APIError
from tabs.profile import render


class FakeAPI:
    def __init__(self, get_calls, patch_calls, post_calls):
        self.get_calls = get_calls
        self.patch_calls = patch_calls
        self.post_calls = post_calls

    def get(self, path):
        self.get_calls.append(path)

        if st.session_state.get("test_get_error"):
            raise APIError("Unable to load profile")

        if path == "/api/v1/users/me":
            return {
                "user": {
                    "id": 1,
                    "name": "Alex",
                    "email": "alex@example.com",
                    "email_verified": True,
                    "created_at": "2026-11-20",
                }
            }

        return {}

    def patch(self, path, payload):
        self.patch_calls.append({
            "path": path,
            "payload": payload,
        })

        if st.session_state.get("test_patch_error"):
            raise APIError("Profile update failed")

        return {
            "user": {
                "id": 1,
                "name": payload["name"],
                "email": "alex@example.com",
                "email_verified": True,
            }
        }

    def post(self, path, payload):
        self.post_calls.append({
            "path": path,
            "payload": payload,
        })

        if st.session_state.get("test_post_error"):
            raise APIError("Request failed")

        return {"success": True}


class FakeLocalStorage:
    def __init__(self):
        self.set_calls = []
        self.delete_all_calls = 0

    def setItem(self, item_key, value, **kwargs):
        self.set_calls.append({
            "key": item_key,
            "value": value,
            "kwargs": kwargs,
        })

    def deleteAll(self):
        self.delete_all_calls += 1


def money(amount):
    return f"₹{float(amount):,.2f}"


def show_error(error):
    st.error(str(error))


if not st.session_state.get("_initialized"):
    st.session_state["user"] = {"id": 1}
    st.session_state["token"] = "test-token"
    st.session_state["selected_group_id"] = 1

    st.session_state["group_memberships"] = [
        {
            "id": 11,
            "user_id": 1,
            "role": "admin",
            "status": "active",
        }
    ]

    st.session_state["get_calls"] = []
    st.session_state["patch_calls"] = []
    st.session_state["post_calls"] = []
    st.session_state["_initialized"] = True

if "local_storage" not in st.session_state:
    st.session_state["local_storage"] = FakeLocalStorage()

local_storage = st.session_state["local_storage"]

api = FakeAPI(
    st.session_state["get_calls"],
    st.session_state["patch_calls"],
    st.session_state["post_calls"],
)

render(
    api=api,
    group_id=1,
    money=money,
    show_error=show_error,
    local_storage=local_storage,
)