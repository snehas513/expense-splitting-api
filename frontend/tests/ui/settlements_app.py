
import streamlit as st

from tabs.settlements import render


class FakeAPI:
    def __init__(self, post_calls):
        self.post_calls = post_calls

    def post(self, path, payload):
        self.post_calls.append({
            "path": path,
            "payload": payload,
        })
        return {"success": True}

    def get(self, path):
        return {
            "settlements": [
                {
                    "id": 101,
                    "sender": {"id": 2, "name": "Jane"},
                    "receiver": {"id": 1, "name": "Alex"},
                    "creator": {"id": 1, "name": "Alex"},
                    "settlement_amount": "350.00",
                    "settlement_date": "2026-11-23",
                    "status": "pending",
                    "note": "Test settlement",
                    "acted_by": None,
                }
            ],
            "pagination": {"has_more": False},
        }


def money(amount):
    return f"₹{float(amount):.2f}"


def show_error(error):
    st.error(str(error))


current_user_id = st.session_state.get("test_current_user_id", 1)

st.session_state["user"] = {"id": current_user_id}
st.session_state["group_memberships"] = []
st.session_state["group_expenses"] = []

if "post_calls" not in st.session_state:
    st.session_state["post_calls"] = []

api = FakeAPI(st.session_state["post_calls"])

render(
    api=api,
    group_id=1,
    money=money,
    show_error=show_error,
)
