import streamlit as st
from api_client import APIError


def render(api, group_id, money, show_error):
    c1, c2, c3 = st.columns(3)
    try:
        balances = api.get(f"/api/v1/groups/{group_id}/balances").get("balances", [])
        expenses = api.get(f"/api/v1/groups/{group_id}/expenses?limit=100").get("expenses", [])
        settlements = api.get(f"/api/v1/groups/{group_id}/settlements?limit=100").get("settlements", [])

        total_members = len(balances)
        total_expenses = len(expenses)
        total_settlements = len(settlements)

        c1.metric("Members", total_members)
        c2.metric("Expenses", total_expenses)
        c3.metric("Settlements", total_settlements)

        st.markdown("#### Current balances")
        if balances:
            for item in balances:
                amount = float(item.get("balance", 0))
                status = "gets back" if amount > 0 else "owes" if amount < 0 else "settled"
                st.write(f'**{item.get("name", "Member")}** {status} **{money(abs(amount))}**')
        else:
            st.info("No balance records.")
    except APIError as exc:
        show_error(exc)
