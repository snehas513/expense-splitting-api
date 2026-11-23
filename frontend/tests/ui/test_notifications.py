from pathlib import Path

from streamlit.testing.v1 import AppTest


APP_PATH = Path(__file__).parent / "notifications_app.py"


def run_app(notifications=None):
    app = AppTest.from_file(str(APP_PATH))

    if notifications is not None:
        app.session_state["notifications"] = notifications

    app.run()
    return app


def test_notifications_are_displayed():
    app = run_app()

    assert not app.exception
    assert any(
        "Jane invited you to Trip Group." in item.value
        for item in app.markdown
    )
    assert any(
        "Your settlement was confirmed." in item.value
        for item in app.markdown
    )


def test_unread_notification_can_be_marked_as_read():
    app = run_app()

    assert len(app.button) == 1
    assert app.button[0].label == "Mark read"

    app.button[0].click().run()

    assert not app.exception
    assert app.session_state["patch_calls"] == [
        {
            "path": "/api/v1/notifications/101/mark_as_read",
            "payload": {},
        }
    ]
    assert app.session_state["notifications"][0]["read"] is True

    app.run()

    assert len(app.button) == 0

def test_read_notifications_do_not_show_mark_read_button():
    notifications = [
        {
            "id": 102,
            "message": "Settlement confirmed.",
            "notification_type": "settlement_confirmation",
            "created_at": "2026-11-22",
            "read": True,
        }
    ]

    app = run_app(notifications)

    assert not app.exception
    assert len(app.button) == 0


def test_empty_notifications_message_is_displayed():
    app = run_app([])

    assert not app.exception
    assert any(
        "No unread notifications." in item.value
        for item in app.info
    )
    assert len(app.button) == 0