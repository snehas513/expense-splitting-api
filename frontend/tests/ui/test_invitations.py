from pathlib import Path

from streamlit.testing.v1 import AppTest


APP_PATH = Path(__file__).parent / "invitations_app.py"


def run_app(role="admin"):
    app = AppTest.from_file(str(APP_PATH))
    app.session_state["test_role"] = role
    app.run()
    return app


def test_received_invitation_is_displayed():
    app = run_app()

    assert not app.exception
    assert any("Trip Group" in item.value for item in app.markdown)
    assert any("Jane" in item.value for item in app.markdown)


def test_user_can_accept_received_invitation():
    app = run_app()

    app.button[0].click().run()

    assert not app.exception
    assert app.session_state["post_calls"][-1] == {
        "path": "/api/v1/groups/2/invitations/101/accept",
        "payload": {},
    }
    assert app.session_state["received_invitations"][0]["status"] == "accepted"
    assert app.session_state["success_message"] == (
        "You joined Trip Group successfully!"
    )


def test_user_can_reject_received_invitation():
    app = run_app()

    app.button[1].click().run()

    assert not app.exception
    assert app.session_state["post_calls"][-1] == {
        "path": "/api/v1/groups/2/invitations/101/reject",
        "payload": {},
    }
    assert app.session_state["received_invitations"][0]["status"] == "rejected"
    assert app.session_state["success_message"] == "Invitation rejected."


def test_admin_can_view_sent_invitations():
    app = run_app()

    assert "/api/v1/groups/1/invitations" in app.session_state["get_calls"]
    assert any("Sam" in item.value for item in app.markdown)
    assert any(button.label == "Revoke invitation" for button in app.button)


def test_admin_can_confirm_revoking_invitation():
    app = run_app()

    app.button[2].click().run()

    assert any(
        "Are you sure you want to revoke the invitation" in item.value
        for item in app.warning
    )

    app.button[2].click().run()

    assert not app.exception
    assert app.session_state["post_calls"][-1] == {
        "path": "/api/v1/groups/1/invitations/201/revoke",
        "payload": {},
    }
    assert app.session_state["sent_invitations"][0]["status"] == "revoked"
    assert app.session_state["success_message"] == "Invitation to Sam revoked."
    assert "pending_revoke_invitation_id" not in app.session_state


def test_admin_can_cancel_revoke_confirmation():
    app = run_app()

    app.button[2].click().run()

    # Buttons after the rerun: Accept, Reject, Confirm revoke, Cancel.
    app.button[3].click().run()

    assert not app.exception
    assert app.session_state["post_calls"] == []
    assert "pending_revoke_invitation_id" not in app.session_state
    assert app.session_state["sent_invitations"][0]["status"] == "pending"


def test_non_admin_cannot_view_sent_invitations_or_revoke():
    app = run_app(role="member")

    assert not app.exception
    assert "/api/v1/groups/1/invitations" not in app.session_state["get_calls"]
    assert not any(
        button.label in {
            "Revoke invitation",
            "Confirm revoke",
        }
        for button in app.button
    )