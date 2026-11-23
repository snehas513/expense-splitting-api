
import streamlit as st
from api_client import APIError


def render_group_selector(api, show_error):
    try:
        groups_response = api.get("/api/v1/groups")
        groups = groups_response.get("groups", [])
    except APIError as exc:
        show_error(exc)
        st.stop()

    st.subheader("Your groups")

    with st.expander("Create a new group"):
        with st.form("create_group_form"):
            group_name = st.text_input("Group name")
            group_description = st.text_area("Description")

            submitted = st.form_submit_button(
                "Create Group",
                type="primary"
            )

        if submitted:
            try:
                api.post(
                    "/api/v1/groups",
                    {
                        "name": group_name.strip(),
                        "description": group_description.strip()
                    }
                )

                st.success("Group created successfully!")
                st.rerun()

            except APIError as exc:
                show_error(exc)

    if not groups:
        st.info("No groups found for this account.")
        st.session_state.pop("selected_group_id", None)
        return None, {}, None

    group_labels = {
        f'{g.get("name", "Group")} (#{g.get("id")})': g.get("id")
        for g in groups
    }

    labels = list(group_labels.keys())
    previous_id = st.session_state.get("selected_group_id")

    default_index = next(
        (
            i for i, label in enumerate(labels)
            if group_labels[label] == previous_id
        ),
        0,
    )

    selected_label = st.selectbox(
        "Select a group",
        labels,
        index=default_index,
    )

    group_id = group_labels[selected_label]
    st.session_state["selected_group_id"] = group_id

    try:
        group_response = api.get(f"/api/v1/groups/{group_id}")
        group = group_response.get("group", {})
    except APIError:
        group = {"id": group_id, "name": selected_label}

    return group_id, group, selected_label
