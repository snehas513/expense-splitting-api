
import streamlit as st

from tabs.balances import render


class FakeAPI:
    def __init__(self, post_calls, get_calls):
        self.post_calls = post_calls
        self.get_calls = get_calls

    def get(self, path):
        self.get_calls.append(path)

        if path == "/api/v1/groups/1/balances":
            return {
                "balances": [
                    {"user_id": 1, "name": "Alex", "balance": "350.00"},
                    {"user_id": 2, "name": "Jane", "balance": "-350.00"},
                ]
            }

        if path == "/api/v1/groups/1/balances/2":
            return {
                "breakdown": {
                    "outstanding_debt": "350.00",
                    "user_owes_member": [
                        {
                            "expense": {
                                "id": 10,
                                "description": "Groceries",
                                "expense_date": "2026-11-23",
                            },
                            "share_amount": "350.00",
                            "allocated_amount": "0.00",
                            "remaining_amount": "350.00",
                        }
                    ],
                    "member_owes_user": [],
                }
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


st.session_state["user"] = {"id": 1}

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
