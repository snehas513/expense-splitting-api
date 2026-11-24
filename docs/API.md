# Expense Splitting API

## Overview

The Expense Splitting API is a RESTful backend built with Ruby on Rails. It supports user authentication, group management, expense tracking, balance calculation, settlements, invitations, and notifications.

The backend is responsible for all financial calculations. Clients should use the calculated balances and settlement information returned by the API rather than calculating them independently.

## Base URL

```text
/api/v1
```

## Authentication

Protected endpoints require a JWT access token.

Include the token in the request header:

```http
Authorization: Bearer <jwt_token>
```

### Authentication flow

1. Register an account.
2. Verify the registered email address.
3. Log in using the verified email and password.
4. Receive a JWT access token.
5. Include the token in subsequent protected API requests.

JWT tokens expire after **one hour**.

Unauthenticated or deactivated users receive:

**401 Unauthorized**

```json
{
  "error": "Unauthorized"
}
```

## Common responses

### Group not found

**404 Not Found**

```json
{
  "error": "Group not found"
}
```

### Active group membership required

For endpoints using the common group membership authorization check:

**403 Forbidden**

```json
{
  "error": "Authenticated user, but no active membership"
}
```

### Validation failure

Most service-level validation failures return:

**422 Unprocessable Entity**

```json
{
  "success": false,
  "errors": [
    "Validation error message"
  ]
}
```

Some controller-level lookup and parameter errors return `400` or `404` instead.

---

# 1. Health

## GET /health

Checks whether the API is running.

**Authentication:** Not required.

**Success — 200 OK**

```json
{
  "status": "ok",
  "message": "Expense Splitting API is running"
}
```

---

# 2. Authentication

## POST /auth/register

Registers a new user and initiates email verification.

**Authentication:** Not required.

**Request body**

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123"
}
```

**Success — 201 Created**

```json
{
  "success": true,
  "message": "Registration successful. Please verify your email.",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

**Business rules**
- Email is normalized by trimming whitespace and converting it to lowercase.
- Email must be unique.
- Password must be at least 8 characters and contain only alphanumeric characters.
- The account must be email-verified before login.
- A verification email is requested after registration.

**Failure**
- `422 Unprocessable Entity` for registration validation or verification email request failures.

## POST /auth/verify_email

Verifies a user's registered email address.

**Authentication:** Not required.

**Request body**

```json
{
  "raw_token": "<verification_token>"
}
```

**Success — 200 OK**

```json
{
  "success": true,
  "message": "Email verification successful. You can login.",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

**Business rules**
- The raw token is matched using its SHA256 digest.
- The verification token must be valid and not expired.
- Successful verification sets the email verification timestamp.

**Failure — 422 Unprocessable Entity**

Returned for invalid or expired tokens or service validation errors.

## POST /auth/login

Authenticates a registered user.

**Authentication:** Not required.

**Request body**

```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Success — 200 OK**

```json
{
  "success": true,
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "email_verified": true,
    "created_at": "2026-11-24T10:00:00Z"
  },
  "auth_token": "<jwt_token>"
}
```

**Business rules**
- Email is normalized before authentication.
- Email verification is required.
- The account must be active.
- The JWT contains the user ID and expires after one hour.

**Failure — 401 Unauthorized**

Possible messages:
- `Invalid email or password`
- `Please verify your email before logging in`
- `Your account is deactivated`

---

# 3. Users

All user endpoints require authentication.

## GET /users/me

Returns the authenticated user's profile.

**Success — 200 OK**

```json
{
  "success": true,
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "email_verified": true,
    "created_at": "2026-11-24T10:00:00Z"
  }
}
```

## PATCH /users/me

Updates the authenticated user's profile.

**Request body**

```json
{
  "name": "John Smith"
}
```

**Success — 200 OK**

```json
{
  "success": true,
  "user": {
    "id": 1,
    "name": "John Smith",
    "email": "john@example.com",
    "email_verified": true,
    "created_at": "2026-11-24T10:00:00Z"
  }
}
```

**Business rules**
- Only the `name` field can be updated through this endpoint.
- Email changes use a separate verification workflow.
- Account status cannot be changed through this endpoint.

**Failure — 422 Unprocessable Entity**

Returns model validation errors.

## POST /users/me/email_change

Requests an email address change.

**Request body**

```json
{
  "new_email": "newemail@example.com"
}
```

**Success — 200 OK**

```json
{
  "success": true
}
```

**Business rules**
- User must have an active account.
- New email must be present and valid.
- New email must differ from the current email.
- New email must not already be used as another user's email or pending email.
- The new email is stored as a pending email until verification.
- A verification email is queued.

**Failure — 422 Unprocessable Entity**

Possible errors:
- `User is required`
- `User must have an active account`
- `New Email is required`
- `Invalid email format`
- `New email must be different from current email`
- `Email has already been taken`

## POST /users/me/email_verification

Verifies a pending email address change.

**Request body**

```json
{
  "raw_token": "<verification_token>"
}
```

**Success — 200 OK**

```json
{
  "success": true,
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "newemail@example.com",
    "email_verified": true,
    "created_at": "2026-11-24T10:00:00Z"
  }
}
```

**Business rules**
- User must have an active account.
- A pending email and valid verification token must exist.
- The token must not be expired.
- Successful verification updates the email, clears pending email and token fields, and updates the verification timestamp.
- A confirmation email is queued.

**Failure — 422 Unprocessable Entity**

Possible errors:
- `User is required`
- `User must have an active account`
- `Raw token is required`
- `Raw token is invalid`
- `Verification token has expired`

## POST /users/me/deactivate

Deactivates the authenticated user's account.

**Request body:** None.

**Success — 200 OK**

```json
{
  "success": true
}
```

**Business rules**
- User must have an active account.
- User must have zero net outstanding balances across active groups.
- If the user is an admin in an active group, another active admin must remain in that group.
- Account status is changed to `deactivated`.
- All active memberships of the user are changed to inactive.

**Failure — 422 Unprocessable Entity**

Possible errors:
- `User is required`
- `User must have an active account`
- `User has outstanding balances to settle`
- `Unable to verify user's outstanding balance for group ID ...`
- `Group must have at least one active admin, group ID ...`

---

# 4. Groups

All group endpoints require authentication.

## POST /groups

Creates a group.

**Request body**

```json
{
  "name": "Trip to Goa",
  "description": "Expenses for our Goa trip"
}
```

**Success — 201 Created**

```json
{
  "success": true,
  "group": {}
}
```

The `group` object uses ActiveRecord serialization. Its exact fields depend on the model attributes.

**Business rules**
- The group is created with `active` status.
- The authenticated user is added as an active admin.
- Group creation and admin membership creation happen in a transaction.

**Failure — 422 Unprocessable Entity**

Returns group validation errors.

## GET /groups

Lists the authenticated user's active groups.

**Success — 200 OK**

```json
{
  "success": true,
  "groups": []
}
```

**Business rules**
- Only active groups are returned.
- The user must have an active membership in each returned group.
- No pagination is implemented.

## GET /groups/:group_id

Returns group details.

**Success — 200 OK**

```json
{
  "success": true,
  "group": {}
}
```

**Business rules**
- The group must exist and be active.
- The authenticated user must have an active membership.

**Failure**
- `404 Not Found` if the group does not exist.
- `422 Unprocessable Entity` for service validation failures.

## PATCH /groups/:group_id

Updates group details.

**Request body**

```json
{
  "name": "Updated Trip Name",
  "description": "Updated description"
}
```

**Success — 200 OK**

```json
{
  "success": true,
  "group": {}
}
```

**Business rules**
- Only `name` and `description` are permitted.
- Only an active admin member can update the group.
- At least one update attribute must be provided.

**Failure — 422 Unprocessable Entity**

Possible errors:
- `Valid update attributes are required`
- `Group not found or you are not an active admin`

Model validation errors may also be returned.

## POST /groups/:group_id/archive

Archives a group.

**Request body:** None.

**Success — 200 OK**

```json
{
  "success": true,
  "group": {}
}
```

**Business rules**
- Only an active admin member can archive the group.
- Group status changes to `archived`.
- All group memberships are changed to inactive.
- Updates happen in a transaction.

**Failure — 422 Unprocessable Entity**

Possible error:
- `Group not found or you are not an active admin`

## GET /groups/:group_id/inviteable_users

Returns users who can be invited to the group.

**Optional query parameter**

| Parameter | Description |
|---|---|
| `query` | Searches user name or email |

**Example**

```http
GET /groups/1/inviteable_users?query=john
```

**Success — 200 OK**

```json
{
  "success": true,
  "users": [
    {
      "id": 5,
      "name": "John Doe",
      "email": "john@example.com"
    }
  ]
}
```

**Business rules**
- Requesting user must have an active account and active admin membership.
- Excludes the requesting user.
- Excludes users who are already active members.
- Excludes users with pending invitations.
- Searches name and email when `query` is provided.
- Results are ordered by name.
- Maximum 20 users are returned.

**Failure — 422 Unprocessable Entity**

Possible errors:
- `User is required`
- `User must have an active account`
- `User is not an active admin member of the group`

---

# 5. Group Memberships

All membership endpoints require authentication.

## GET /groups/:group_id/members

Lists group memberships.

**Success — 200 OK**

```json
{
  "success": true,
  "group_memberships": []
}
```

**Business rules**
- The authenticated user must have an active membership in the group.
- Returns the latest membership record per user.
- Includes active and inactive membership records.
- Results are ordered by membership ID.

## POST /groups/:group_id/leave

Allows the authenticated user to leave a group.

**Request body:** None.

**Success — 200 OK**

```json
{
  "success": true,
  "membership": {}
}
```

**Business rules**
- User must have an active account and active membership.
- User must have zero net outstanding balance in the group.
- User must have no pending settlements involving them.
- If the user is an admin, another active admin must remain.
- Membership is marked inactive; the record is retained.

**Failure — 422 Unprocessable Entity**

Possible errors:
- `Group is required`
- `User is required`
- `User must have an active account`
- `User is not an active member of the group`
- `Unable to verify user's outstanding balance`
- `User has outstanding balances to settle`
- `User has pending settlements to resolve`
- `Group must have at least one active admin`

## DELETE /groups/:group_id/members/:target_user_id

Removes a member from the group.

**Request body:** None.

**Success — 200 OK**

```json
{
  "success": true,
  "membership": {}
}
```

**Business rules**
- Requesting user must have an active account and active admin membership.
- Target user must have an active account and active membership.
- Admin cannot remove themselves.
- Target user must have zero net outstanding balance.
- Target membership is marked inactive.
- Membership record is retained.

**Failure — 422 Unprocessable Entity**

Possible errors:
- `Admin must have an active account`
- `Admin is not an active admin member of the group`
- `Admin cannot remove themselves`
- `User must have an active account`
- `User is not an active member of the group`
- `Unable to verify user's outstanding balance`
- `User has outstanding balances to settle`

## PATCH /groups/:group_id/members/:target_user_id/role

Changes a member's role.

**Request body**

```json
{
  "role": "admin"
}
```

Allowed roles:
- `admin`
- `member`

**Success — 200 OK**

```json
{
  "success": true,
  "membership": {}
}
```

**Business rules**
- Requesting user must have an active account and active admin membership.
- Target user must have an active account and active membership.
- Admin cannot change their own role.
- The requested role must be valid.
- The requested role must differ from the user's current role.

**Failure — 422 Unprocessable Entity**

Possible errors:
- `Admin must have an active account`
- `Admin is not an active admin member of the group`
- `Admin cannot change their own role`
- `User must have an active account`
- `User is not an active member of the group`
- `Role must be one of: admin, member`
- `User already has this role`

---

# 6. Group Invitations

All invitation endpoints require authentication.

## POST /groups/:group_id/invitations

Invites a user to join a group.

**Request body**

```json
{
  "invited_user_id": 5
}
```

**Success — 201 Created**

```json
{
  "success": true,
  "invitation": {}
}
```

**Business rules**
- Inviter must have an active account and active admin membership.
- Invitee must have an active account.
- Users cannot invite themselves.
- Invitee cannot already be an active group member.
- A pending invitation for the same group and user cannot already exist.
- Invitation is created with `pending` status and a sent timestamp.
- A `group_invitation` notification is created for the invitee.
- Invitation and notification creation are transactional.

**Failure — 422 Unprocessable Entity**

Possible errors:
- `Invited By is required`
- `Invited by must have an active account and active admin membership in the group`
- `Invited User is required`
- `Invited User must have an active account`
- `Invited User is already an active member of the group`
- `A user cannot invite themselves`
- `Pending invitation already exists for this group/user`

Notification errors may also be returned.

## POST /groups/:group_id/invitations/:id/accept

Accepts a group invitation.

**Request body:** None.

**Success — 200 OK**

```json
{
  "success": true,
  "invitation": {}
}
```

**Business rules**
- Only the invited user can accept the invitation.
- User must have an active account.
- Invitation must be pending.
- Group must be active.
- User must not already be an active member.
- Invitation status changes to `accepted`.
- Response timestamp is recorded.
- An active membership with role `member` is created.
- The operation locks the invitation while processing.

**Failure — 422 Unprocessable Entity**

Possible errors:
- `Invitation is required`
- `Invitation must be pending`
- `Group must be active`
- `User is required`
- `User must have an active account`
- `User is invalid`
- `User is already an active member of the group`

## POST /groups/:group_id/invitations/:id/reject

Rejects a group invitation.

**Request body:** None.

**Success — 200 OK**

```json
{
  "success": true,
  "invitation": {}
}
```

**Business rules**
- Only the invited user can reject the invitation.
- User must have an active account.
- Invitation must be pending.
- Group must be active.
- Invitation status changes to `rejected`.
- Response timestamp is recorded.
- No membership is created.
- The operation locks the invitation while processing.

**Failure — 422 Unprocessable Entity**

Uses the same invitation and user validation errors as the accept endpoint.

## GET /groups/:group_id/invitations

Lists pending invitations for a group.

**Success — 200 OK**

```json
{
  "success": true,
  "invitations": []
}
```

**Business rules**
- User must have an active account and active admin membership.
- Only pending invitations are returned.
- No pagination is implemented.

**Failure — 422 Unprocessable Entity**

Possible errors:
- `User is required`
- `User must have an active account`
- `User is not an active admin member of the group`

## GET /invitations

Lists pending invitations received by the authenticated user.

**Success — 200 OK**

```json
{
  "success": true,
  "invitations": []
}
```

**Business rules**
- User must have an active account.
- Only pending invitations addressed to the authenticated user are returned.
- No pagination is implemented.

**Failure — 422 Unprocessable Entity**

Possible errors:
- `User is required`
- `User must have an active account`

## POST /groups/:group_id/invitations/:id/revoke

Revokes a pending invitation.

**Request body:** None.

**Success — 200 OK**

```json
{
  "success": true,
  "invitation": {}
}
```

**Business rules**
- Requesting user must have an active account and active admin membership in the invitation's group.
- Invitation must be pending.
- Group must be active.
- Invitation status changes to `revoked`.
- Revocation timestamp is recorded.

**Failure — 422 Unprocessable Entity**

Possible errors:
- `Invitation is required`
- `Invitation must be pending`
- `Group must be active`
- `User is required`
- `User must have an active account`
- `User is not an active admin member of the group`

---

# 7. Expenses

All expense endpoints require authentication.

## POST /groups/:group_id/expenses

Creates an expense in a group.

**Request body**

```json
{
  "payer_id": 2,
  "participant_ids": [1, 2, 3],
  "amount": "1000.00",
  "description": "Dinner",
  "expense_date": "2026-11-24",
  "note": "Dinner after the trip"
}
```

`note` is optional.

**Success — 201 Created**

```json
{
  "success": true,
  "expense": {}
}
```

The expense object uses ActiveRecord serialization. Its exact fields depend on the model attributes.

**Business rules**
- Group must be valid.
- Creator, payer, and participants must have active accounts and active group memberships.
- Payer must be included in the participants.
- At least two participants are required.
- Participant IDs must be unique.
- Amount must be a valid, finite, positive number.
- Maximum amount: `9999999999.99`.
- Amount cannot have more than two decimal places.
- Expense is split equally among participants.
- Amounts are split in paise to preserve the exact total.
- Any remainder paise are distributed to participants in their supplied order.
- Expense and participant records are created transactionally.

**Controller-level failures**
- `400 Bad Request` if `participant_ids` is not an array:

```json
{
  "error": "participant_ids must be an array"
}
```

- `404 Not Found` if the payer does not exist:

```json
{
  "error": "Payer not found"
}
```

- `404 Not Found` if any participant does not exist:

```json
{
  "error": "All participants should exist"
}
```

Other validation failures return `422 Unprocessable Entity`.

## GET /groups/:group_id/expenses

Lists active group expenses.

**Optional query parameters**

| Parameter | Description |
|---|---|
| `limit` | Maximum number of expenses per page |
| `cursor` | Cursor returned by the previous response |

The default limit is defined by `CursorPagination::DEFAULT_LIMIT`.

**Example**

```http
GET /groups/1/expenses?limit=10
```

**Success — 200 OK**

```json
{
  "success": true,
  "expenses": [],
  "pagination": {
    "next_cursor": "<next_cursor>",
    "has_more": true
  }
}
```

**Business rules**
- Only active expenses belonging to the group are returned.
- Results are ordered newest first.
- Cursor pagination uses `expense_date` and record ID.
- One additional record is fetched to determine whether another page exists.
- `next_cursor` is used to request the next page.
- `has_more` indicates whether more records are available.
- The authenticated user must have an active group membership.

**Failure — 422 Unprocessable Entity**

Returns group, limit, or cursor validation errors.

---

# 8. Balances

All balance endpoints require authentication and active group membership.

## GET /groups/:group_id/balances

Returns calculated balances for group members.

**Success — 200 OK**

The response is serialized through `Balances::Serializer`.

The exact response structure should be confirmed against a live API response before being treated as a stable client contract.

**Calculation rules**
- Includes active group members.
- Also includes users with historical participation in active expenses.
- Includes users involved in confirmed settlements.
- Active expenses contribute to balances.
- Confirmed settlements adjust balances.
- When a member paid an expense, their balance increases by the amount paid minus their own share.
- Other participants' balances decrease by their respective shares.
- The sum of all group balances must equal zero.

**Calculation integrity checks**
- The payer must be an expense participant.
- Participant shares must equal the expense amount.
- The sum of calculated balances must be zero.

**Failure — 422 Unprocessable Entity**

Possible errors:
- Group validation errors.
- `Payer is not an expense participant for expense ...`
- `Participant shares do not match expense amount for expense ...`
- `The sum of group balances must be zero`

## GET /groups/:group_id/balances/:member_id

Returns the financial breakdown between the authenticated user and another group member.

**Success — 200 OK**

```json
{
  "success": true,
  "breakdown": {
    "outstanding_debt": "<amount>",
    "user_owes_member": [],
    "member_owes_user": []
  }
}
```

Each expense entry in the two directional lists contains:

```json
{
  "expense": {},
  "share_amount": "<amount>",
  "allocated_amount": "<amount>",
  "remaining_amount": "<amount>"
}
```

**Business rules**
- Both users must have active accounts and active group memberships.
- The two users must be different.
- `outstanding_debt` is calculated by the pairwise balance service.
- `user_owes_member` represents expenses paid by the requested member in which the authenticated user participated.
- `member_owes_user` represents expenses paid by the authenticated user in which the requested member participated.
- Pending and confirmed settlement allocations are deducted from the corresponding expense shares.
- Entries with zero or negative remaining amounts are excluded.

**Pairwise calculation**

```text
Outstanding debt =
  Sender's expense shares owed by receiver
  - Receiver's expense shares owed by sender
  - Confirmed settlements from sender to receiver
  + Confirmed settlements from receiver to sender

Minimum value = 0
```

**Failure — 422 Unprocessable Entity**

Possible errors:
- `User is required`
- `Member is required`
- `User must have an active account and active membership in the group`
- `Member must have an active account and active membership in the group`
- `User and Member must be different users`

Pairwise calculation errors may also be returned.

---

# 9. Settlements

All settlement endpoints require authentication.

## POST /groups/:group_id/settlements

Creates a settlement request between two group members.

**Request body**

```json
{
  "sender_id": 1,
  "receiver_id": 2,
  "settlement_amount": "500.00",
  "settlement_date": "2026-11-24",
  "note": "Partial payment",
  "allocations": [
    {
      "expense_id": 12,
      "allocation_amount": "500.00"
    }
  ]
}
```

`note` is optional. Allocations are required.

**Success — 201 Created**

```json
{
  "success": true,
  "settlement": {}
}
```

**Business rules**
- Sender, receiver, and creator must have active accounts and active group memberships.
- Sender and receiver must be different users.
- Only the sender or receiver can create the settlement.
- Settlement amount must be positive, finite, and have at most two decimal places.
- Maximum settlement amount: `9999999999.99`.
- Settlement date must be valid.
- Allocations must be a non-empty array.
- Duplicate expense allocations are not allowed.
- Every allocated expense must be active and belong to the group.
- Allocation amounts must be positive, finite, and have at most two decimal places.
- Total allocation amount must equal the settlement amount.
- Each allocated expense must have been paid by the receiver.
- Sender must have participated in each allocated expense.
- Allocations cannot exceed the sender's remaining share after pending and confirmed allocations.
- Settlement amount cannot exceed available outstanding debt after accounting for pending settlements in the same direction.

The settlement is created with:
- `status: pending`
- `acted_by: null`

Settlement, expense allocations, and notification creation happen transactionally.

A `settlement_request` notification is created for the receiver. If notification creation fails, the settlement transaction is rolled back.

**Failure — 422 Unprocessable Entity**

Possible errors:
- `Sender is required`
- `Receiver is required`
- `Sender and receiver must be different users`
- `Creator must be either the sender or receiver`
- `Settlement Amount must be greater than 0`
- `Settlement Amount cannot have more than two decimal places`
- `Settlement Date is invalid`
- `Allocations must be a non-empty array`
- `Duplicate expense allocations are not allowed`
- `Total allocations must equal settlement amount`
- `Settlement amount exceeds the available amount`
- `Allocation amount for expense ID ... exceeds remaining amount`

Other validation and notification errors may also be returned.

The controller returns `404 Not Found` if the sender or receiver ID cannot be found.

## POST /groups/:group_id/settlements/:id/confirm

Confirms a pending settlement.

**Request body:** None.

**Success — 200 OK**

```json
{
  "success": true,
  "settlement": {}
}
```

**Business rules**
- Settlement must belong to the specified group.
- Settlement must still be pending.
- Creator, sender, receiver, and acting user must have active accounts and active group memberships.
- Only the sender or receiver can perform the action.
- Acting user must be different from the creator.
- Settlement status changes to `confirmed`.
- `acted_by` records the user who confirmed it.
- A `settlement_confirmation` notification is sent to the creator.
- Settlement update and notification creation are transactional.

**Failure — 422 Unprocessable Entity**

Returns shared settlement action validation errors.

## POST /groups/:group_id/settlements/:id/reject

Rejects a pending settlement.

**Request body:** None.

**Success — 200 OK**

```json
{
  "success": true,
  "settlement": {}
}
```

**Business rules**
- Settlement must belong to the specified group.
- Settlement must still be pending.
- Creator, sender, receiver, and acting user must have active accounts and active group memberships.
- Only the sender or receiver can perform the action.
- Acting user must be different from the creator.
- Settlement status changes to `rejected`.
- `acted_by` records the user who rejected it.
- A `settlement_rejection` notification is sent to the creator.
- Settlement update and notification creation are transactional.

**Failure — 422 Unprocessable Entity**

Returns shared settlement action validation errors.

## POST /groups/:group_id/settlements/:id/cancel

Cancels a pending settlement.

**Request body:** None.

**Success — 200 OK**

```json
{
  "success": true,
  "settlement": {}
}
```

**Business rules**
- Settlement must belong to the specified group.
- Settlement must still be pending.
- Creator, sender, receiver, and acting user must have active accounts and active group memberships.
- Only the settlement creator can cancel it.
- Settlement status changes to `cancelled`.
- `acted_by` records the creator.
- No notification is created.
- The status update is transactional.

**Failure — 422 Unprocessable Entity**

Possible specific error:
- `Acted By must be the creator`

Shared settlement action validation errors may also be returned.

## GET /groups/:group_id/settlements

Lists settlements belonging to a group.

**Optional query parameters**

| Parameter | Description |
|---|---|
| `status` | Filters settlements by status |
| `limit` | Maximum number of settlements per page |
| `cursor` | Cursor returned by the previous response |

Allowed statuses:
- `pending`
- `confirmed`
- `rejected`
- `cancelled`

**Example**

```http
GET /groups/1/settlements?status=pending&limit=10
```

**Success — 200 OK**

```json
{
  "success": true,
  "settlements": [],
  "pagination": {
    "next_cursor": "<next_cursor>",
    "has_more": false
  }
}
```

**Business rules**
- Returns settlements belonging to the specified group.
- Applies the status filter when supplied.
- Results are ordered newest first.
- Cursor pagination uses `settlement_date` and record ID.
- One additional record is fetched to determine whether another page exists.
- The authenticated user must have an active group membership.

**Failure — 422 Unprocessable Entity**

Possible error:

```text
Status must be one of: pending, confirmed, rejected, cancelled
```

Group, limit, and cursor validation errors may also be returned.

---

# 10. Notifications

All notification endpoints require authentication.

## GET /notifications

Lists unread notifications for the authenticated user.

**Success — 200 OK**

```json
{
  "success": true,
  "notifications": []
}
```

**Business rules**
- Only unread notifications are returned.
- Results are ordered by creation time, newest first.
- No pagination is implemented.

## PATCH /notifications/:id/mark_as_read

Marks a notification as read.

**Request body:** None.

**Success — 200 OK**

```json
{
  "success": true,
  "notification": {}
}
```

**Business rules**
- Notification is looked up within the authenticated user's notifications.
- If already read, no update is performed.
- Otherwise, `read` is set to `true`.

**Failure — 422 Unprocessable Entity**

Possible error:
- `Notification is required`

Model validation errors may also be returned.

---

# 11. Notification Types

Notifications are created by the backend when relevant events occur.

| Notification type | Trigger |
|---|---|
| `group_invitation` | A user is invited to join a group |
| `settlement_request` | A settlement request is created |
| `settlement_confirmation` | A settlement request is confirmed |
| `settlement_rejection` | A settlement request is rejected |

New notifications are created with `read: false`.

---

# 12. Pagination

Expenses and settlements use cursor-based pagination.

The response includes:

```json
{
  "pagination": {
    "next_cursor": "<next_cursor>",
    "has_more": true
  }
}
```

### How to paginate

1. Make the initial request, optionally specifying `limit`.
2. Read `next_cursor` from the response.
3. Pass that cursor in the next request.
4. Continue while `has_more` is `true`.

Example:

```http
GET /groups/1/expenses?limit=10
```

Next page:

```http
GET /groups/1/expenses?limit=10&cursor=<next_cursor>
```

The default page limit is defined by `CursorPagination::DEFAULT_LIMIT`.

---

# 13. API Endpoint Summary

All paths below are relative to `/api/v1`.

| Resource | Method | Endpoint | Authentication |
|---|---|---|---|
| Health | GET | `/health` | No |
| Authentication | POST | `/auth/register` | No |
| Authentication | POST | `/auth/verify_email` | No |
| Authentication | POST | `/auth/login` | No |
| Users | GET | `/users/me` | Yes |
| Users | PATCH | `/users/me` | Yes |
| Users | POST | `/users/me/email_change` | Yes |
| Users | POST | `/users/me/email_verification` | Yes |
| Users | POST | `/users/me/deactivate` | Yes |
| Groups | POST | `/groups` | Yes |
| Groups | GET | `/groups` | Yes |
| Groups | GET | `/groups/:group_id` | Yes |
| Groups | PATCH | `/groups/:group_id` | Yes |
| Groups | POST | `/groups/:group_id/archive` | Yes |
| Groups | GET | `/groups/:group_id/inviteable_users` | Yes |
| Memberships | GET | `/groups/:group_id/members` | Yes |
| Memberships | POST | `/groups/:group_id/leave` | Yes |
| Memberships | DELETE | `/groups/:group_id/members/:target_user_id` | Yes |
| Memberships | PATCH | `/groups/:group_id/members/:target_user_id/role` | Yes |
| Invitations | POST | `/groups/:group_id/invitations` | Yes |
| Invitations | POST | `/groups/:group_id/invitations/:id/accept` | Yes |
| Invitations | POST | `/groups/:group_id/invitations/:id/reject` | Yes |
| Invitations | GET | `/groups/:group_id/invitations` | Yes |
| Invitations | GET | `/invitations` | Yes |
| Invitations | POST | `/groups/:group_id/invitations/:id/revoke` | Yes |
| Expenses | POST | `/groups/:group_id/expenses` | Yes |
| Expenses | GET | `/groups/:group_id/expenses` | Yes |
| Balances | GET | `/groups/:group_id/balances` | Yes |
| Balances | GET | `/groups/:group_id/balances/:member_id` | Yes |
| Settlements | POST | `/groups/:group_id/settlements` | Yes |
| Settlements | POST | `/groups/:group_id/settlements/:id/confirm` | Yes |
| Settlements | POST | `/groups/:group_id/settlements/:id/reject` | Yes |
| Settlements | POST | `/groups/:group_id/settlements/:id/cancel` | Yes |
| Settlements | GET | `/groups/:group_id/settlements` | Yes |
| Notifications | GET | `/notifications` | Yes |
| Notifications | PATCH | `/notifications/:id/mark_as_read` | Yes |

---

# 14. Notes

- All financial calculations are performed by the backend.
- Expense splitting is equal, with paise-level remainder distribution to preserve the exact total.
- Settlement allocations track which expenses a settlement covers.
- Pending and confirmed settlement allocations are considered when calculating remaining expense shares.
- Only confirmed settlements affect the group's overall balances.
- Group membership and account status are checked by the relevant services.
- Group membership records are retained when a user leaves or is removed.
- Email changes require a separate verification process.
- Account reactivation is not exposed through the current public API.

**Response examples:** Empty objects and arrays are used where the exact ActiveRecord serialization or serializer output was not verified. Confirm those structures against live API responses before treating them as fixed response contracts.