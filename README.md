# Expense Splitting API

A RESTful backend application for managing shared expenses, tracking group balances, and recording settlements between members.

The application allows users to create groups, split expenses, track individual debts, and manage settlement requests for payments made outside the application.

## Project Overview

Expense Splitting API supports:

- User registration and JWT-based authentication.
- Group creation and membership management.
- Group invitations and role-based access.
- Shared expense creation with equal splitting.
- Individual balance calculation and debt tracking.
- Partial settlements with expense-level allocations.
- Settlement confirmation, rejection, and cancellation.
- In-app notifications.
- Expense and settlement history.

## Technology Stack

- **Backend:** Ruby on Rails (API mode)
- **Language:** Ruby
- **Database:** MySQL 8.4
- **Authentication:** JWT
- **Containerization:** Docker and Docker Compose
- **Testing:** RSpec
- **API Style:** REST

## Project Structure

```text
expense-splitting-api/
├── backend/       # Rails API application
├── frontend/      # Streamlit frontend (planned)
├── docs/          # Project documentation
└── README.md
```

## Key Features

### Authentication and User Management
- JWT-based authentication.
- User profile management.
- Email change with verification.
- Account deactivation with business-rule validation.

### Groups and Memberships
- Group creation, updates, and archival.
- Admin and regular member roles.
- Invitation acceptance, rejection, and revocation.
- Membership management with historical records.
- Safeguards for group administration.

### Expense Management
- Expense creation with equal splitting.
- Multiple participants and a single payer.
- Exact share calculation, including rounding adjustments.
- Expense history with cursor-based pagination.

### Balance Calculation
- Group-level balance calculation.
- Individual outstanding debts.
- Confirmed settlements reduce balances.
- Pending, rejected, and cancelled settlements do not affect balances.

### Settlement Management
- Settlement requests for external payments.
- Partial settlements.
- Allocation of settlements across multiple expenses.
- Confirmation, rejection, and cancellation workflows.
- Settlement history with cursor-based pagination.

### Notifications
- In-app notifications for:
  - Group invitations.
  - Settlement requests.
  - Settlement confirmations.
  - Settlement rejections.
- Notification listing and read status management.

## Engineering and Data Integrity

The application incorporates several backend design considerations:

- Monetary values use MySQL `DECIMAL(12,2)` instead of floating-point types.
- Expense shares are calculated so that their sum exactly matches the expense amount.
- Database foreign keys and unique constraints protect relational integrity.
- Historical membership records are retained when members leave or are removed.
- Settlement allocations are tracked against individual expenses.
- Pending and confirmed allocations are considered when validating available settlement amounts.
- Database transactions protect multi-step operations.
- Group-level locking provides concurrency protection for settlement operations.
- RSpec tests cover models, services, and API request behaviour.

## Current Project Status

The core backend functionality for the MVP has been implemented.

**Implemented**
- Authentication and user management.
- Groups, memberships, and invitations.
- Expense creation and history.
- Balance calculation.
- Settlement lifecycle and expense allocations.
- In-app notifications.
- Cursor-based pagination.
- Transactional operations and concurrency protection.

**Planned / Deferred**
- Streamlit frontend.
- Detailed API documentation with request and response examples.
- Automated audit logging.
- Expense deletion and restoration.
- Group soft deletion and restoration.
- Background job processing using Sidekiq and Redis.
- Email and push notifications.

## Running the Project

Setup and execution instructions will be documented as part of the project documentation.

The application uses Docker for the development environment and MySQL for persistence.

## Testing

The backend uses RSpec for automated testing.

Run the test suite from the `backend/` directory:

```bash
bundle exec rspec
```

## Future Development

The next development phase focuses on:

1. Completing API documentation.
2. Building the Streamlit frontend.
3. Integrating the frontend with the Rails API.
4. Improving project setup and deployment documentation.

