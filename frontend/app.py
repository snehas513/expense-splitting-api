
import json
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
    group_management,
)

st.set_page_config(page_title="Expense Splitter", page_icon="💸", layout="wide")
st.title("💸 Expense Splitter")
st.caption("A simple frontend for your Expense Splitting API")

# Developer settings.
with st.sidebar.expander("Developer Settings"):
    API_URL = st.text_input(
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

api = client()

# Show success messages after reruns.
if st.session_state.get("success_message"):
    st.toast(st.session_state.pop("success_message"), icon="✅")

# Select the group.
group_id, group, selected_label = render_group_selector(api, show_error)
st.header(group.get("name", selected_label))

# Load memberships centrally so all tabs can reuse them.
try:
    memberships_response = api.get(
        f"/api/v1/groups/{group_id}/members"
    )
    st.session_state["group_memberships"] = memberships_response.get(
        "group_memberships", []
    )
except APIError as exc:
    show_error(exc)
    st.session_state["group_memberships"] = []

# Account section.
with st.sidebar:
    st.caption("🟢 Authenticated")

    with st.expander("Account"):
        profile.render(api, group_id, money, show_error, local_storage)

        st.divider()

        if st.button("Log out", use_container_width=True):
            local_storage.deleteAll()
            for key in (
                "token",
                "user",
                "selected_group_id",
                "group_memberships",
            ):
                st.session_state.pop(key, None)
            st.rerun()

# Main application tabs.
tabs = st.tabs([
    "Overview",
    "Expenses",
    "Balances",
    "Settlements",
    "Members",
    "Invitations",
    "Notifications",
    "Group Management",
])

with tabs[0]:
    overview.render(api, group_id, money, show_error)

with tabs[1]:
    expenses.render(api, group_id, money, show_error)

with tabs[2]:
    balances.render(api, group_id, money, show_error)

with tabs[3]:
    settlements.render(api, group_id, money, show_error)

with tabs[4]:
    members.render(api, group_id, money, show_error)

with tabs[5]:
    invitations.render(api, group_id, money, show_error)

with tabs[6]:
    notifications.render(api, group_id, money, show_error)

with tabs[7]:
    group_management.render(api, group_id, group, show_error)

st.caption(
    "Frontend MVP · Rails API remains responsible for validation, "
    "authorization, and business rules."
)
