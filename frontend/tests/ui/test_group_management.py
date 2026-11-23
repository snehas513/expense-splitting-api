
import pytest
from streamlit.testing.v1 import AppTest


@pytest.fixture
def app():
    return AppTest.from_file("tests/ui/group_management_app.py").run()


def test_admin_can_view_group_management(app):
    headings = [m.value for m in app.markdown]

    assert "#### Update group name" in headings
    assert "#### Manage member roles" in headings
    assert "#### Remove a member" in headings
    assert "#### Archive Group" in headings
    assert "#### Leave group" in headings

def test_admin_can_update_group_name(app):
    app.text_input[0].set_value("Weekend Trip")
    app.button[0].click().run()

    assert app.session_state["patch_calls"] == [
        {
            "path": "/api/v1/groups/1",
            "payload": {"name": "Weekend Trip"},
        }
    ]


def test_blank_group_name_is_rejected(app):
    app.text_input[0].set_value("   ")
    app.button[0].click().run()

    assert "Group name cannot be blank." in [
        element.value for element in app.error
    ]
    assert app.session_state["patch_calls"] == []


def test_group_name_update_api_error_is_displayed(app):
    app.session_state["test_patch_error"] = True
    app.text_input[0].set_value("Weekend Trip")
    app.button[0].click().run()

    assert "Update failed" in [
        element.value for element in app.error
    ]


def test_admin_can_promote_member(app):
    promote_button = next(
        button for button in app.button
        if button.label == "Promote to Admin"
    )
    promote_button.click().run()

    assert app.session_state["patch_calls"] == [
        {
            "path": "/api/v1/groups/1/members/2/role",
            "payload": {"role": "admin"},
        }
    ]


def test_admin_can_demote_member(app):
    memberships = app.session_state["group_memberships"]
    memberships[1]["role"] = "admin"

    app.run()

    demote_button = next(
        button for button in app.button
        if button.label == "Demote to Member"
    )
    demote_button.click().run()

    assert app.session_state["patch_calls"] == [
        {
            "path": "/api/v1/groups/1/members/2/role",
            "payload": {"role": "member"},
        }
    ]


def test_admin_cannot_change_own_role(app):
    assert "You cannot change your own role." in [
        element.value for element in app.caption
    ]


def test_regular_member_cannot_manage_group(app):
    app.session_state["group_memberships"][0]["role"] = "member"
    app.run()

    assert "Only group admins can manage group settings and members." in [
        element.value for element in app.info
    ]
    assert "Update group name" not in [
        element.value for element in app.markdown
    ]
    assert "#### Leave group" in [
        element.value for element in app.markdown
    ]


def test_admin_can_start_member_removal(app):
    remove_button = next(
        button for button in app.button
        if button.label == "Remove member"
    )
    remove_button.click().run()

    assert app.session_state["pending_remove_user_id"] == 2
    assert any(
        element.label == "Confirm removal"
        for element in app.button
    )


def test_admin_can_cancel_member_removal(app):
    app.session_state["pending_remove_user_id"] = 2
    app.run()

    next(
        button for button in app.button
        if button.label == "Cancel"
    ).click().run()

    assert "pending_remove_user_id" not in app.session_state
    assert app.session_state["delete_calls"] == []


def test_admin_can_confirm_member_removal(app):
    app.session_state["pending_remove_user_id"] = 2
    app.run()

    next(
        button for button in app.button
        if button.label == "Confirm removal"
    ).click().run()

    assert app.session_state["delete_calls"] == [
        "/api/v1/groups/1/members/2"
    ]
    assert "pending_remove_user_id" not in app.session_state


def test_member_removal_api_error_is_displayed(app):
    app.session_state["pending_remove_user_id"] = 2
    app.session_state["test_delete_error"] = True
    app.run()

    next(
        button for button in app.button
        if button.label == "Confirm removal"
    ).click().run()

    assert "Removal failed" in [
        element.value for element in app.error
    ]


def test_admin_can_start_group_archiving(app):
    next(
        button for button in app.button
        if button.label == "Archive group"
    ).click().run()

    assert app.session_state["pending_archive_group"] is True
    assert any(
        button.label == "Confirm archive"
        for button in app.button
    )


def test_admin_can_cancel_group_archiving(app):
    app.session_state["pending_archive_group"] = True
    app.run()

    next(
        button for button in app.button
        if button.label == "Cancel"
    ).click().run()

    assert "pending_archive_group" not in app.session_state
    assert app.session_state["post_calls"] == []


def test_admin_can_confirm_group_archiving(app):
    app.session_state["pending_archive_group"] = True
    app.session_state["selected_group_id"] = 1
    app.run()

    next(
        button for button in app.button
        if button.label == "Confirm archive"
    ).click().run()

    assert app.session_state["post_calls"] == [
        {
            "path": "/api/v1/groups/1/archive",
            "payload": {},
        }
    ]
    assert "selected_group_id" not in app.session_state
    assert "pending_archive_group" not in app.session_state


def test_admin_can_start_leaving_group(app):
    next(
        button for button in app.button
        if button.label == "Leave group"
    ).click().run()

    assert app.session_state["pending_leave_group"] is True


def test_member_can_cancel_leaving_group(app):
    app.session_state["pending_leave_group"] = True
    app.run()

    next(
        button for button in app.button
        if button.label == "Cancel"
    ).click().run()

    assert "pending_leave_group" not in app.session_state
    assert app.session_state["post_calls"] == []


def test_member_can_confirm_leaving_group(app):
    app.session_state["pending_leave_group"] = True
    app.run()

    next(
        button for button in app.button
        if button.label == "Confirm leave"
    ).click().run()

    assert app.session_state["post_calls"] == [
        {
            "path": "/api/v1/groups/1/leave",
            "payload": {},
        }
    ]
    assert "pending_leave_group" not in app.session_state


def test_leave_group_api_error_is_displayed(app):
    app.session_state["pending_leave_group"] = True
    app.session_state["test_post_error"] = True
    app.run()

    next(
        button for button in app.button
        if button.label == "Confirm leave"
    ).click().run()

    assert "Request failed" in [
        element.value for element in app.error
    ]
