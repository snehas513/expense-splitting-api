
from pathlib import Path

from streamlit.testing.v1 import AppTest


APP_FILE = Path(__file__).parent / "members_app.py"


def test_members_page_loads_successfully():
    app = AppTest.from_file(str(APP_FILE))
    app.run()

    assert not app.exception

    assert (
        "/api/v1/groups/1/inviteable_users"
        in app.session_state["get_calls"]
    )


def test_active_members_are_displayed():
    app = AppTest.from_file(str(APP_FILE))
    app.run()

    assert not app.exception
    assert len(app.dataframe) == 1

    rows = app.dataframe[0].value
    names = rows["Name"].tolist()

    assert "Alex" in names
    assert "Jane" in names
    assert "Inactive User" not in names


def test_admin_can_invite_member():
    app = AppTest.from_file(str(APP_FILE))
    app.run()

    app.selectbox[0].set_value("Sam (sam@example.com)")

    next(
        button for button in app.button
        if button.label == "Send Invitation"
    ).click().run()

    assert not app.exception

    assert app.session_state["success_message"] == (
        "Invitation sent to Sam."
    )

    assert app.session_state["post_calls"] == [
        {
            "path": "/api/v1/groups/1/invitations",
            "payload": {"invited_user_id": 3},
        }
    ]


def test_non_admin_cannot_invite_members():
    app = AppTest.from_file(str(APP_FILE))
    app.session_state["test_role"] = "member"
    app.run()

    assert not app.exception

    assert not any(
        button.label == "Send Invitation"
        for button in app.button
    )

    assert (
        "/api/v1/groups/1/inviteable_users"
        not in app.session_state["get_calls"]
    )
