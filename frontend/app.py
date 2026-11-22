import json
import time
import streamlit as st
from streamlit_local_storage import LocalStorage
from api_client import APIError
from utils import client, show_error, money
from components.auth import render_login
from components.group_selector import render_group_selector
from tabs import (
    overview,
    members,
    expenses,
    balances,
    settlements,
    notifications,
    invitations,
    profile,
)

st.set_page_config(page_title="Expense Splitter", page_icon="💸", layout="wide")
st.title("💸 Expense Splitter")
st.caption("A simple frontend for your Expense Splitting API")

API_URL = st.sidebar.text_input(
    "Rails API base URL",
    value=st.session_state.get("api_url", "http://localhost:3000"),
    help="Use the address reachable from the machine running Streamlit.",
)
st.session_state["api_url"] = API_URL.rstrip("/")

# Browser local storage keeps the JWT across page refreshes.
local_storage = LocalStorage()
if "token" not in st.session_state:
    restored_token = local_storage.getItem("expense_splitter_auth_token")
    if restored_token:
        st.session_state["token"] = restored_token

# Restore user independently from the token.
if st.session_state.get("token") and "user" not in st.session_state:
    restored_user = local_storage.getItem("expense_splitter_user")
    if restored_user:
        try:
            st.session_state["user"] = json.loads(restored_user)
        except (TypeError, json.JSONDecodeError):
            st.session_state["user"] = {}

if not st.session_state.get("token"):
    render_login(local_storage, show_error)
    st.stop()

with st.sidebar:
    st.success("Authenticated")
    if st.button("Log out"):
        local_storage.deleteAll()
        time.sleep(0.5)
        for key in ("token", "user", "selected_group_id"):
            st.session_state.pop(key, None)
        st.rerun()

api = client()

# Show success messages after reruns.
if st.session_state.get("success_message"):
    st.toast(st.session_state.pop("success_message"), icon="✅")

group_id, group, selected_label = render_group_selector(api, show_error)
st.header(group.get("name", selected_label))

tabs = st.tabs([
    "Overview", "Members", "Expenses", "Balances",
    "Settlements", "Notifications", "Invitations", "Profile",
])

with tabs[0]:
    overview.render(api, group_id, money, show_error)

with tabs[1]:
    members.render(api, group_id, money, show_error)

with tabs[2]:
    expenses.render(api, group_id, money, show_error)

with tabs[3]:
    balances.render(api, group_id, money, show_error)

with tabs[4]:
    settlements.render(api, group_id, money, show_error)

with tabs[5]:
    notifications.render(api, group_id, money, show_error)

with tabs[6]:
    invitations.render(api, group_id, money, show_error)

with tabs[7]:
    profile.render(api, group_id, money, show_error, local_storage)

st.caption("Frontend MVP · Rails API remains responsible for validation, authorization, and business rules.")
