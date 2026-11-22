import json
import streamlit as st
import time
from api_client import APIClient, APIError


def render_login(local_storage, show_error):
    st.subheader("Login")
    with st.form("login_form"):
        email = st.text_input("Email")
        password = st.text_input("Password", type="password")
        submitted = st.form_submit_button("Log in", type="primary")
    if submitted:
        try:
            result = APIClient(st.session_state["api_url"]).post(
                "/api/v1/auth/login",
                {"email": email.strip(), "password": password},
            )
            token = (
                result.get("auth_token")
                or result.get("token")
                or result.get("jwt")
            )
            if not token:
                st.error("Login succeeded, but no token field was found in the response. Check the login response shape.")
                st.json(result)
                return
            user = result.get("user", {})
            local_storage.setItem("expense_splitter_auth_token", token, key="save_auth_token")
            local_storage.setItem("expense_splitter_user", json.dumps(user), key="save_user")
            time.sleep(0.5)
            st.session_state["token"] = token
            st.session_state["user"] = user
            st.success("Logged in.")
            st.rerun()
        except APIError as exc:
            show_error(exc)

    with st.expander("Register a new account"):
        with st.form("register_form"):
            name = st.text_input("Name", key="register_name")
            reg_email = st.text_input("Email", key="register_email")
            reg_password = st.text_input("Password", type="password", key="register_password")
            register = st.form_submit_button("Register")
        if register:
            try:
                result = APIClient(st.session_state["api_url"]).post(
                    "/api/v1/auth/register",
                    {"name": name.strip(), "email": reg_email.strip(), "password": reg_password},
                )
                st.success("Registration request completed. Check the API response for next steps.")
                st.json(result)
            except APIError as exc:
                show_error(exc)

        st.caption("Email verification is handled by your Rails API. Use the verification link/token delivered by your configured mailer.")
