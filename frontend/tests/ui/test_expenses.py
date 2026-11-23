
from pathlib import Path

from streamlit.testing.v1 import AppTest


APP_FILE = Path(__file__).parent / "expenses_app.py"


def test_expenses_page_loads_successfully():
    app = AppTest.from_file(str(APP_FILE))
    app.run()

    assert not app.exception

    assert app.session_state["get_calls"] == [
        "/api/v1/groups/1/expenses?limit=20"
    ]


def test_create_expense_form_is_displayed():
    app = AppTest.from_file(str(APP_FILE))
    app.run()

    assert not app.exception

    assert any(
        button.label == "Create expense"
        for button in app.button
    )

    assert any(
        item.label == "Description"
        for item in app.text_input
    )


def test_expense_history_is_displayed():
    app = AppTest.from_file(str(APP_FILE))
    app.run()

    assert not app.exception

    assert any(
        "Groceries" in item.label
        for item in app.expander
    )


def test_create_expense_submits_correct_payload():
    app = AppTest.from_file(str(APP_FILE))
    app.run()

    app.text_input[0].set_value("Dinner")
    app.number_input[0].set_value(500.00)
    app.multiselect[0].set_value([1, 2])

    app.button[0].click().run()

    assert not app.exception

    calls = app.session_state["post_calls"]

    assert len(calls) == 1
    assert calls[0]["path"] == "/api/v1/groups/1/expenses"

    payload = calls[0]["payload"]

    assert payload["payer_id"] == 1
    assert payload["participant_ids"] == [1, 2]
    assert payload["amount"] == "500.00"
    assert payload["description"] == "Dinner"
    assert payload["note"] == ""
    assert "expense_date" in payload
