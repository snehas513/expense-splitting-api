
from pathlib import Path

import pytest
from streamlit.testing.v1 import AppTest


APP_FILE = Path(__file__).parent / "settlements_app.py"


@pytest.mark.parametrize(
    "user_id, expected_buttons",
    [
        (1, {"Cancel settlement"}),
        (2, {"Confirm", "Reject"}),
        (3, set()),
    ],
)
def test_settlement_actions_for_user(user_id, expected_buttons):
    app = AppTest.from_file(str(APP_FILE))
    app.session_state["test_current_user_id"] = user_id
    app.run()

    assert not app.exception

    actual_buttons = {button.label for button in app.button}
    assert actual_buttons == expected_buttons


def test_other_party_can_confirm_settlement():
    app = AppTest.from_file(str(APP_FILE))
    app.session_state["test_current_user_id"] = 2
    app.run()

    next(b for b in app.button if b.label == "Confirm").click().run()

    assert not app.exception
    assert app.session_state["success_message"] == (
        "Settlement confirmed successfully."
    )
    assert app.session_state["post_calls"] == [
        {
            "path": "/api/v1/groups/1/settlements/101/confirm",
            "payload": {},
        }
    ]


def test_other_party_can_reject_settlement():
    app = AppTest.from_file(str(APP_FILE))
    app.session_state["test_current_user_id"] = 2
    app.run()

    next(b for b in app.button if b.label == "Reject").click().run()

    assert not app.exception
    assert app.session_state["success_message"] == (
        "Settlement rejected successfully."
    )
    assert app.session_state["post_calls"] == [
        {
            "path": "/api/v1/groups/1/settlements/101/reject",
            "payload": {},
        }
    ]


def test_creator_can_cancel_settlement():
    app = AppTest.from_file(str(APP_FILE))
    app.session_state["test_current_user_id"] = 1
    app.run()

    next(
        b for b in app.button if b.label == "Cancel settlement"
    ).click().run()

    assert not app.exception
    assert app.session_state["success_message"] == (
        "Settlement cancelled successfully."
    )
    assert app.session_state["post_calls"] == [
        {
            "path": "/api/v1/groups/1/settlements/101/cancel",
            "payload": {},
        }
    ]
