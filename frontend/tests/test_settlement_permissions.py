
import pytest

from tabs.settlements import get_settlement_permissions


@pytest.mark.parametrize(
    "current_user_id, expected",
    [
        # Alex created the settlement: Alex can cancel.
        (1, {"can_cancel": True, "can_respond": False}),

        # Jane is the other party: Jane can respond.
        (2, {"can_cancel": False, "can_respond": True}),

        # An unrelated user cannot perform either action.
        (3, {"can_cancel": False, "can_respond": False}),
    ],
)
def test_settlement_permissions(current_user_id, expected):
    permissions = get_settlement_permissions(
        current_user_id=current_user_id,
        sender_id=2,
        receiver_id=1,
        creator_id=1,
    )

    assert permissions == expected
