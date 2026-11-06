# Expense Splitting API — MVP Requirements

## 1. Project Overview

A shared-expense application that allows users to create groups, record expenses, split costs, track outstanding balances, and record settlements.

### Technology Stack
- Backend: Ruby on Rails (API mode)
- Database: MySQL
- Frontend: Streamlit (planned)
- Infrastructure: Docker
- Authentication: Token-based authentication (planned)
- Background jobs: Sidekiq and Redis (planned)
- Testing: RSpec

## 2. MVP Scope

The MVP includes:
- User registration and authentication
- User profiles
- Groups and memberships
- Group invitations
- Expense creation and history
- Equal expense splitting
- Balance calculation
- Partial settlements
- In-app notifications
- Group and expense archival/deletion

Deferred:
- Unequal expense splitting
- Multiple currencies
- Email and push notifications
- Payment processing inside the application

## 3. User Accounts

- Users can register and log in.
- One user can belong to multiple groups.
- Users can update their name and profile picture independently.
- Email changes require verification of the new email.
- Password changes require the current password.
- Password reset is supported through email.
- Account deletion is implemented as deactivation.
- Deactivated users cannot log in until they reactivate.
- Historical financial records retain the user's original name.
- Users can reactivate their accounts independently.

### Account Deletion Conditions
A user can deactivate their account only when:
- All outstanding balances are settled.
- No pending settlement requests exist.

## 4. Groups and Memberships

### Group Management
- Any user can create a group.
- The creator becomes the first admin.
- A group has a name and optional description.
- Only admins can update group details.
- A group must have at least two active members.
- Multiple admins are supported.
- A group must always have at least one admin.

### Roles
- Admin
- Regular member

Admins can promote regular members to admins.

### Invitations
- Only admins can invite or add people.
- Every new membership requires invitation acceptance, including invitations to existing users.
- Invitations can be pending, accepted, rejected, or revoked.
- Pending invitations do not expire automatically.
- Admins can revoke pending invitations.
- A fresh invitation is allowed after a previous invitation was rejected.
- New members join as regular members.

### Leaving and Removing Members
- A member can leave if they have no outstanding balance.
- Admins can remove members only if they have no outstanding balance.
- Admins can remove other admins, subject to the last-admin safeguard.
- A sole admin must promote another member before leaving.
- A returning member rejoins as a regular member.
- Historical records are retained when someone leaves.
- Outstanding balances carry forward if a member rejoins.

### Group Archival and Deletion
- A group can be archived only when all outstanding balances are zero and no settlement requests are pending.
- Any admin can restore an archived group.
- Groups support soft deletion.
- Historical expenses, settlements, and membership records are retained.
- Admins can restore a soft-deleted group.
- Restoring a group does not automatically reactivate previous members or restore people who had left.
- Previous members must rejoin through the normal membership process.

## 5. Expenses

### Expense Creation
Each expense contains:
- Description (required)
- Amount (required)
- Expense date (required)
- Optional note
- One payer
- Multiple participants
- Creator
- Creation timestamp

### Rules
- One expense has exactly one payer.
- The payer must be included as a participant.
- At least two participants are required.
- All participants must be active members of the same group.
- Equal splitting is supported in the MVP.
- Currency is INR only.
- Amounts support two decimal places.
- Decimal database types must be used, not floating-point types.
- Rounding differences must be allocated so participant shares add up exactly to the expense total.
- Expenses are immutable after creation.

### Expense Deletion
- The creator can delete their own expense.
- An admin can delete any expense.
- Deletion is soft deletion.
- Deleted expenses do not contribute to current balances.
- Admins can restore deleted expenses.
- An expense cannot be deleted if it has contributed to a confirmed settlement.

## 6. Balances

- Balances are calculated independently for each group.
- All group members can view everyone's outstanding balances.
- All members can view total group expenses.
- Individual debts are displayed; debt simplification is not part of the MVP.
- Only confirmed settlements reduce outstanding balances.
- Pending, rejected, or cancelled settlements do not reduce balances.
- Deleted expenses are excluded from current balances.

### Expense History
All group members can view the complete expense history, including expenses they did not participate in.

History displays:
- Expense description and amount
- Payer and participants
- Creator
- Expense date
- Creation timestamp

Users can filter/search expenses by:
- Date range
- Payer
- Description

## 7. Settlements

A settlement records an external payment made through UPI, cash, bank transfer, or another payment method. The application does not process the payment itself.

### Settlement Workflow
1. A debtor transfers money to the creditor outside the application.
2. The debtor creates a settlement request.
3. The request remains pending.
4. The creditor confirms or rejects the request.
5. Only confirmation reduces the outstanding balance.

### Settlement Rules
- Partial payments are supported.
- Multiple pending requests between the same sender and receiver are allowed.
- The combined amount of confirmed settlements and pending requests cannot exceed the outstanding debt.
- The receiver can confirm or reject the exact requested amount.
- The receiver cannot modify the amount.
- A rejected request remains in history; the debt remains unchanged.
- The sender can create another request after rejection.
- The sender can cancel their own pending request.
- Only pending requests can be cancelled.
- Cancelling a request does not change the debt.
- An optional note is supported.

### Settlement Visibility
Settlement request details are visible only to the sender and receiver.

Users can view their settlement history with these statuses:
- Pending
- Confirmed
- Rejected
- Cancelled

Settlement records should retain:
- Sender and receiver
- Amount
- Status
- Optional note
- Creation and update timestamps
- Actor responsible for confirmation, rejection, or cancellation

## 8. Notifications

In-app notifications are included in the MVP.

Notifications are generated for:
- New group invitations
- New settlement requests
- Settlement confirmations
- Settlement rejections

Notifications are accessible through an in-app notification list or bell.

Email and push notifications are deferred.

## 9. Key Data Integrity Requirements

The implementation must enforce:
- A payer is always an expense participant.
- Expense participants belong to the same group.
- An expense has at least two participants.
- Participant shares sum exactly to the expense amount.
- Only confirmed settlements affect balances.
- Pending plus confirmed settlement amounts cannot exceed the outstanding debt.
- A group always has at least one admin.
- Members with outstanding balances cannot leave or be removed.
- An expense contributing to a confirmed settlement cannot be deleted.
- Group archival requires zero outstanding balances and no pending settlement requests.

## 10. Business Rules and Validations

### 1. Users
- Email must be unique and verified before it can replace the existing email.
- Passwords must be securely stored using `password_digest`, never as plain text.
- A user can belong to multiple groups.
- A user can deactivate their account only when all outstanding balances are settled and no settlement requests are pending.
- Deactivated users cannot log in. They can reactivate their account by logging in again.
- Historical records must retain the user's original name.

### 2. Groups and Memberships
- A group must have at least two active members.
- Every group must have at least one active admin.
- Only admins can update group details, invite members, promote members, remove members, or restore archived/deleted groups.
- Every invitation must be accepted before the invited user becomes a member.
- Only one pending invitation can exist for the same user and group at a time.
- A user can have only one active membership in a group at a time.
- A returning member gets the regular member role by default.
- A member can leave a group only when their outstanding balance is zero.
- An admin can leave only if another active admin remains.
- Members with outstanding dues cannot be removed.
- Groups can be archived only when all balances are zero and no settlement requests are pending.
- Group deletion is soft deletion. Historical records must be retained.

### 3. Expenses
- Every expense must belong to exactly one group.
- An expense must have a positive amount and use INR.
- Amounts must support two decimal places.
- Every expense must have exactly one payer and one creator.
- The payer must be one of the expense participants.
- An expense must have at least two participants.
- All participants must be active members of the same group.
- A user can appear only once in an expense.
- Expenses are split equally in the MVP.
- Individual participant shares must be mandatory and positive.
- The sum of participant shares must equal the expense amount exactly.
- Rounding differences must be distributed so that the shares add up to the original amount.
- Expenses are immutable after creation.
- The creator can delete their own expense; an admin can delete any expense.
- Deleted expenses do not contribute to balances.
- An expense cannot be deleted if it has contributed to a confirmed settlement.
- Deleted expenses can be restored by an admin.

### 4. Balances
- Balances are calculated independently for each group.
- Balances are derived from active expenses and confirmed settlements.
- Pending, rejected, and cancelled settlement requests do not reduce balances.
- Individual debts must be displayed without debt simplification.
- All group members can view group balances and expense history.

### 5. Settlements
- A settlement records an external payment; the application does not transfer money.
- Every settlement must belong to one group and have one sender and one receiver.
- Sender and receiver must be different users.
- The settlement amount must be positive and mandatory.
- A settlement request must not exceed the outstanding debt after accounting for existing confirmed and pending requests.
- Multiple pending requests between the same sender and receiver are allowed, provided their combined amount does not exceed the outstanding debt.
- Only the receiver can confirm or reject a pending request.
- The sender can cancel their own pending request.
- Confirmed settlements reduce the outstanding balance.
- Rejected and cancelled requests do not reduce balances.
- Settlement history must be retained.
- Settlement request details are visible only to the sender and receiver.

### 6. Notifications
- Every notification must belong to one user.
- Notification message and notification type are mandatory.
- New notifications must have `read = false` by default.
- The MVP supports in-app notifications for group invitations and settlement requests, confirmations, and rejections.

### 7. Database and Data Integrity
- Required fields must have database `NOT NULL` constraints.
- Monetary fields must use `DECIMAL(12,2)`, not floating-point types.
- Unique constraints must prevent duplicate user emails and duplicate expense participants.
- Foreign keys must protect relationships between records.
- Business rules involving multiple records, such as settlement limits and group admin requirements, must be enforced in application logic with appropriate database transactions and concurrency protection.
- Historical records must be retained when users, groups, memberships, expenses, or settlements are deactivated, archived, or soft-deleted.

### 8.  AuditTrail
- Records important actions performed across the application.
- Stores the actor, affected record, action, and relevant changes.
- Maintains historical information for auditing and troubleshooting.

## 11. Database Design and Next Development Phase

### 11.1 Database Design

The database design covers the following:

1. **Entities and responsibilities**
   - User
   - Group
   - Membership
   - Invitation
   - Expense
   - ExpenseParticipant
   - Settlement
   - Notification
   - AuditTrail

2. **Relationships**
   - One-to-many and many-to-many relationships between entities.
   - Foreign key relationships and ownership.
   - Historical membership and transaction records.

3. **Attributes and constraints**
   - Required and optional attributes.
   - Unique constraints and foreign keys.
   - Data types, nullability, and default values.
   - Business validations and data integrity rules.

4. **Balance calculation**
   - Balances are derived from expense and settlement records.
   - Confirmed settlements reduce outstanding balances.
   - Pending, rejected, and cancelled settlements do not reduce balances.

### 11.2 Next Development Phase

The next step is implementing the database design in Rails.

We will:

1. Create Rails migrations, one table at a time.
2. Define foreign keys, indexes, and database constraints.
3. Create ActiveRecord models and associations.
4. Implement model validations and business rules.
5. Add tests to verify data integrity and business behaviour.

Implementation will follow the agreed MVP requirements and use MySQL 8.4.

## 12. Current Project Status

- Rails API application initialized.
- MySQL configured through Docker.
- Development and test databases created.
- Health-check endpoint implemented and verified:
  `GET /api/v1/health`
- GitHub repository created and initial project pushed.

Repository: https://github.com/snehas513/expense-splitting-api

