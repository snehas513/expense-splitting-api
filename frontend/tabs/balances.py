import streamlit as st
from api_client import APIError


def render(api, group_id, money, show_error):
    st.markdown("#### Group balances")
    try:
        balances = api.get(f"/api/v1/groups/{group_id}/balances").get("balances", [])
        if balances:
            for item in balances:
                amount = float(item.get("balance", 0))
                label = "is owed" if amount > 0 else "owes" if amount < 0 else "settled"
                st.write(f'**{item.get("name", "Member")}** {label} **{money(abs(amount))}**')
            st.caption("Positive balances are receivable; negative balances are payable.")
        else:
            st.info("No balances found.")
    except APIError as exc:
        show_error(exc)
