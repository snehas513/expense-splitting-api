import streamlit as st

from tabs.overview import render
from api_client import APIError


class FakeAPI:
    def get(self, path):
        if st.session_state.get("test_api_error"):
            raise APIError("Something went wrong")

        if path.endswith("/balances"):
            return {
                "balances": st.session_state["balances"]
            }

        if path.endswith("/expenses?limit=100"):
            return {
                "expenses": st.session_state["expenses"]
            }

        if path.endswith("/settlements?limit=100"):
            return {
                "settlements": st.session_state["settlements"]
            }

        return {}


def money(amount):
    return f"₹{float(amount):,.2f}"


def show_error(error):
    st.error(str(error))


if "balances" not in st.session_state:
    st.session_state["balances"] = [
        {"name": "Alex", "balance": 500},
        {"name": "Jane", "balance": -300},
        {"name": "Sam", "balance": 0},
    ]

if "expenses" not in st.session_state:
    st.session_state["expenses"] = [{}, {}]

if "settlements" not in st.session_state:
    st.session_state["settlements"] = [{}]

api = FakeAPI()

render(
    api=api,
    group_id=1,
    money=money,
    show_error=show_error,
)