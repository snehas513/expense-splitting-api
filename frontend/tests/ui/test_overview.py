from pathlib import Path

from streamlit.testing.v1 import AppTest


APP_PATH = Path(__file__).parent / "overview_app.py"


def run_app(balances=None, expenses=None, settlements=None, api_error=False):
    app = AppTest.from_file(str(APP_PATH))

    if balances is not None:
        app.session_state["balances"] = balances

    if expenses is not None:
        app.session_state["expenses"] = expenses

    if settlements is not None:
        app.session_state["settlements"] = settlements

    app.session_state["test_api_error"] = api_error

    app.run()
    return app


def test_overview_displays_correct_metrics():
    app = run_app()

    assert not app.exception
    assert [metric.label for metric in app.metric] == [
        "Members",
        "Expenses",
        "Settlements",
    ]
    assert [metric.value for metric in app.metric] == ["3", "2", "1"]


def test_positive_balance_is_displayed():
    app = run_app(
        balances=[{"name": "Alex", "balance": 500}]
    )

    assert any(
        "Alex" in item.value and "gets back" in item.value
        for item in app.markdown
    )


def test_negative_balance_is_displayed():
    app = run_app(
        balances=[{"name": "Jane", "balance": -300}]
    )

    assert any(
        "Jane" in item.value and "owes" in item.value
        for item in app.markdown
    )


def test_zero_balance_is_displayed_as_settled():
    app = run_app(
        balances=[{"name": "Sam", "balance": 0}]
    )

    assert any(
        "Sam" in item.value and "settled" in item.value
        for item in app.markdown
    )


def test_empty_balances_message_is_displayed():
    app = run_app(balances=[])

    assert not app.exception
    assert any(
        "No balance records." in item.value
        for item in app.info
    )


def test_api_error_is_displayed():
    app = run_app(api_error=True)

    assert not app.exception
    assert any(
        "Something went wrong" in item.value
        for item in app.error
    )