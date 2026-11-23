
from pathlib import Path

from streamlit.testing.v1 import AppTest


APP_FILE = Path(__file__).parent / "balances_app.py"


def test_balances_page_loads_successfully():
    app = AppTest.from_file(str(APP_FILE))
    app.run()

    assert not app.exception

    assert app.session_state["get_calls"] == [
        "/api/v1/groups/1/balances",
        "/api/v1/groups/1/balances/2",
    ]


def test_pairwise_balance_is_displayed():
    app = AppTest.from_file(str(APP_FILE))
    app.run()

    assert not app.exception

    metrics = {
        metric.label: metric.value
        for metric in app.metric
    }

    assert metrics["You owe Jane"] == "₹350.00"


def test_settlement_form_is_displayed():
    app = AppTest.from_file(str(APP_FILE))
    app.run()

    assert not app.exception

    app.multiselect[0].select(
        "Groceries · 2026-11-23 · Remaining: ₹350.00"
    ).run()

    assert not app.exception

    assert any(
        button.label == "Create settlement"
        for button in app.button
    )


def test_expense_breakdown_is_loaded():
    app = AppTest.from_file(str(APP_FILE))
    app.run()

    assert not app.exception

    assert any(
        "Your share of expenses paid by Jane" in element.value
        for element in app.markdown
    )

    assert any(
        "Groceries" in element.value
        for element in app.markdown
    )
