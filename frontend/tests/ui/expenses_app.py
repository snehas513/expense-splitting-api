
import streamlit as st

from tabs.expenses import render


class FakeAPI:
    def __init__(self, post_calls, get_calls):
        self.post_calls = post_calls
        self.get_calls = get_calls

    def get(self, path):
        self.get_calls.append(path)

        return {
            "expenses": [
                {
                    "id": 101,
                    "description": "Groceries",
                    "amount": "700.00",
                    "expense_date": "2026-11-23",
                    "payer": {"id": 1, "name": "Alex"},
                    "participants": [
                        {
                            "user": {"id": 1, "name": "Alex"},
                            "share_amount": "350.00",
                        },
                        {
                            "user": {"id": 2, "name": "Jane"},
                            "share_amount": "350.00",
                        },
                    ],
                }
            ],
            "pagination": {"has_more": False},
        }

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


st.session_state["group_memberships"] = [
    {
        "status": "active",
        "user": {
            "id": 1,
            "name": "Alex",
            "email": "alex@example.com",
        },
    },
    {
        "status": "active",
        "user": {
            "id": 2,
            "name": "Jane",
            "email": "jane@example.com",
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
