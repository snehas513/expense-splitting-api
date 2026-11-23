
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

local_storage = LocalStorage()


def clear_authentication():
    for key in (
        "expense_splitter_auth_token",
        "expense_splitter_user",
    ):
        try:
            local_storage.deleteItem(
                key,
                key=f"clear_{key}",
            )
        except KeyError:
            pass

    for key in (
        "token",
        "user",
        "selected_group_id",
        "group_memberships",
        "group_expenses",
    ):
        st.session_state.pop(key, None)


# Restore JWT from browser local storage.
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

# Show login if no token exists.
if not st.session_state.get("token"):
    render_login(local_storage, show_error)
    st.stop()

api = client()

# Validate the restored JWT before loading the application.
try:
    api.get("/api/v1/groups")

except APIError as exc:
    if exc.status_code == 401:
        clear_authentication()
        st.rerun()

    show_error(exc)
    st.stop()

# Verify email when the user returns through the email link.
verification_token = st.query_params.get("token")

if verification_token:
    try:
        verification_response = api.post(
            "/api/v1/users/me/email_verification",
            {"raw_token": verification_token},
        )

        verified_user = verification_response.get("user", {})

        if verified_user:
            st.session_state["user"] = verified_user
            local_storage.setItem(
                "expense_splitter_user",
                json.dumps(verified_user),
                key="verify_user_email",
            )

        st.session_state["success_message"] = (
            "Your email address has been verified successfully."
        )

    except APIError as exc:
        show_error(exc)

    finally:
        if "token" in st.query_params:
            del st.query_params["token"]

# Show success messages after reruns.
if st.session_state.get("success_message"):
    st.toast(st.session_state.pop("success_message"), icon="✅")

# Select the group.
group_id, group, selected_label = render_group_selector(api, show_error)

# Account section.
with st.sidebar:
    st.caption("🟢 Authenticated")

    with st.expander("Account"):
        profile.render(api, group_id, money, show_error, local_storage)

        st.divider()

        if st.button("Log out", use_container_width=True):
            clear_authentication()
            st.rerun()

# Invitations are available even when the user has no active groups.
if group_id is None:
    invitations.render(api, None, money, show_error)

else:
    st.header(group.get("name", selected_label))

    # Load memberships centrally.
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
