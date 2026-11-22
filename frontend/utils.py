import streamlit as st
from api_client import APIClient


def client():
    return APIClient(st.session_state["api_url"], st.session_state.get("token"))


def show_error(exc):
    st.error(str(exc))


def money(value):
    try:
        return f"₹{float(value):,.2f}"
    except (TypeError, ValueError):
        return str(value)
