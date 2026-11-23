from pathlib import Path
import json

from streamlit.testing.v1 import AppTest


APP_PATH = Path(__file__).parent / "profile_app.py"


def run_app(**options):
    app = AppTest.from_file(str(APP_PATH))

    for key, value in options.items():
        app.session_state[key] = value

    app.run()
    return app


def click_button(app, label):
    button = next(
        button for button in app.button
        if button.label == label
    )
    button.click().run()


def test_profile_details_are_displayed():
    app = run_app()

    assert not app.exception
    assert any("alex@example.com" in item.value for item in app.markdown)
    assert any("Email verified" in item.value for item in app.markdown)
    assert any("Yes" in item.value for item in app.markdown)
    assert any("2026-11-20" in item.value for item in app.markdown)
    assert any("Admin" in item.value for item in app.markdown)


def test_user_can_update_profile_name():
    app = run_app()

    app.text_input[0].set_value("Alex Smith")
    click_button(app, "Save changes")

    assert not app.exception
    assert app.session_state["patch_calls"] == [
        {
            "path": "/api/v1/users/me",
            "payload": {"name": "Alex Smith"},
        }
    ]

    assert app.session_state["user"]["name"] == "Alex Smith"
    assert app.session_state["success_message"] == (
        "Profile updated successfully."
    )

    storage = app.session_state["local_storage"]
    assert len(storage.set_calls) == 1
    assert storage.set_calls[0]["key"] == "expense_splitter_user"
    assert json.loads(storage.set_calls[0]["value"])["name"] == "Alex Smith"


def test_blank_profile_name_is_rejected():
    app = run_app()

    app.text_input[0].set_value("   ")
    click_button(app, "Save changes")

    assert not app.exception
    assert app.session_state["patch_calls"] == []
    assert any(
        "Name cannot be blank." in item.value
        for item in app.error
    )


def test_profile_update_api_error_is_displayed():
    app = run_app(test_patch_error=True)

    app.text_input[0].set_value("Alex Smith")
    click_button(app, "Save changes")

    assert not app.exception
    assert any(
        "Profile update failed" in item.value
        for item in app.error
    )


def test_user_can_request_email_change():
    app = run_app()

    app.text_input[1].set_value("alex.new@example.com")
    click_button(app, "Send verification email")

    assert not app.exception
    assert app.session_state["post_calls"] == [
        {
            "path": "/api/v1/users/me/email_change",
            "payload": {"new_email": "alex.new@example.com"},
        }
    ]
    assert app.session_state["success_message"] == (
        "Verification email sent. Please check your inbox."
    )


def test_blank_new_email_is_rejected():
    app = run_app()

    app.text_input[1].set_value("   ")
    click_button(app, "Send verification email")

    assert not app.exception
    assert app.session_state["post_calls"] == []
    assert any(
        "Please enter a new email address." in item.value
        for item in app.error
    )


def test_email_change_api_error_is_displayed():
    app = run_app(test_post_error=True)

    app.text_input[1].set_value("alex.new@example.com")
    click_button(app, "Send verification email")

    assert not app.exception
    assert any(
        "Request failed" in item.value
        for item in app.error
    )


def test_deactivation_requires_confirmation():
    app = run_app()

    click_button(app, "Deactivate account")

    assert not app.exception
    assert any(
        "Are you sure you want to deactivate your account?"
        in item.value
        for item in app.error
    )
    assert app.session_state["confirm_account_deactivation"] is True
    assert app.session_state["post_calls"] == []


def test_user_can_cancel_account_deactivation():
    app = run_app()

    click_button(app, "Deactivate account")
    click_button(app, "Cancel")

    assert not app.exception
    assert "confirm_account_deactivation" not in app.session_state
    assert app.session_state["post_calls"] == []


def test_user_can_confirm_account_deactivation():
    app = run_app()

    click_button(app, "Deactivate account")
    click_button(app, "Confirm deactivation")

    assert not app.exception
    assert app.session_state["post_calls"] == [
        {
            "path": "/api/v1/users/me/deactivate",
            "payload": {},
        }
    ]

    storage = app.session_state["local_storage"]
    assert storage.delete_all_calls == 1

    for key in (
        "token",
        "user",
        "selected_group_id",
        "group_memberships",
        "confirm_account_deactivation",
    ):
        assert key not in app.session_state


def test_profile_loading_api_error_is_displayed():
    app = run_app(test_get_error=True)

    assert not app.exception
    assert any(
        "Unable to load profile" in item.value
        for item in app.error
    )