# Expense Splitting API

A RESTful expense-splitting application with a Ruby on Rails backend and Streamlit frontend for managing shared expenses, group balances, and settlements.

## Overview

Expense Splitter helps users manage shared expenses within groups. Users can create groups, invite members, record expenses, track balances, and settle outstanding amounts.

The application provides:

- User registration, email verification, and JWT-based authentication.
- Group creation and membership management.
- Expense creation with equal splitting among participants.
- Group-level and pairwise balance calculations.
- Partial settlements with expense-level allocation tracking.
- Settlement confirmation, rejection, and cancellation.
- Notifications for group invitations and settlement activities.
- A Streamlit frontend integrated with the Rails API.

## Tech Stack

- **Backend:** Ruby on Rails (API mode)
- **Language:** Ruby
- **Database:** MySQL 8.4
- **Authentication:** JWT
- **Frontend:** Streamlit
- **Frontend Language:** Python
- **Containerization:** Docker and Docker Compose
- **Backend Testing:** RSpec
- **Frontend Testing:** Pytest and Streamlit AppTest
- **API:** REST

## Project Structure

```text
expense-splitting-api/
├── backend/       # Rails API application
├── frontend/      # Streamlit frontend
├── docs/          # Project documentation
└── README.md
```

## Key Features

### 1. Authentication and User Management

- User registration with email verification.
- JWT-based authentication.
- Login restricted to verified users.
- User profile retrieval and name updates.
- Email change with verification.
- Account deactivation.

### 2. Groups and Membership

- Create, update, and archive groups.
- Group creator is automatically assigned the admin role.
- Invite users to groups.
- Accept, reject, and revoke invitations.
- Manage group membership and member roles.
- Allow members to leave groups subject to balance and pending settlement checks.
- Preserve membership history when members leave or are removed.
- Enforce safeguards around admin and membership operations.

### 3. Expense Management

- Create expenses within a group.
- Support multiple participants with a single payer.
- Split expenses equally among participants.
- Handle rounding adjustments to ensure the total shares match the expense amount.
- Retrieve expense history with cursor-based pagination.

### 4. Balance Management

- Calculate group-level balances.
- Calculate pairwise net balances between members.
- Track individual amounts owed and receivable.
- View expense-wise outstanding amounts between members.
- Reflect confirmed settlements in balance calculations.
- Pending, rejected, and cancelled settlements do not affect balances.

### 5. Settlements

- Create settlement requests between group members.
- Support partial settlements.
- Allocate settlement amounts against individual expenses.
- Confirm, reject, or cancel settlement requests.
- Prevent allocations beyond the available outstanding amount.
- Retrieve settlement history with cursor-based pagination.

### 6. Invitations and Notifications

- Send group invitations to existing users.
- Accept, reject, and revoke invitations.
- Generate notifications for group invitations and settlement activities.
- Retrieve user notifications.
- Mark individual notifications as read.

### 7. Streamlit Frontend

- User registration, email verification, and login.
- Group overview and group management.
- Expense creation and history.
- Group balances and member-wise breakdowns.
- Settlement creation and management.
- Member and invitation management.
- Notification management.
- User profile management and account deactivation.

## Engineering and Data Integrity

- **Financial precision:** Uses `DECIMAL(12,2)` for monetary values instead of floating-point types.
- **Accurate expense splitting:** Ensures participant shares add up exactly to the original expense amount, including rounding adjustments.
- **Database constraints:** Uses foreign keys, unique indexes, and check constraints to enforce data integrity.
- **Historical records:** Retains inactive membership records instead of permanently removing membership history.
- **Settlement allocation tracking:** Tracks how settlement amounts are allocated against individual expenses.
- **Transaction management:** Uses database transactions to keep related operations consistent.
- **Concurrency handling:** Uses group-level locking to protect settlement allocation operations from concurrent requests.
- **Backend-owned financial calculations:** Keeps balance and settlement calculations in the Rails backend rather than duplicating financial logic in the frontend.
- **Automated testing:** Uses RSpec for backend model, service, and API request specifications, and Pytest with Streamlit AppTest for frontend testing.

## Getting Started

### Prerequisites

Make sure the following are installed:

- Git
- Docker
- Docker Compose

### 1. Clone the repository

```bash
git clone https://github.com/snehas513/expense-splitting-api.git
cd expense-splitting-api
```

### 2. Configure environment variables and credentials

Create a `.env` file inside the `backend/` directory.

For local development, configure:

```env
MYSQL_ROOT_PASSWORD=root
MYSQL_USER=root
MYSQL_PASSWORD=root
```

Add any other environment variables required by the application, such as email delivery credentials.

The JWT signing secret must also be configured in Rails credentials.

Do not commit `.env`, `config/master.key`, or other secret credentials to Git.

### 3. Build and start the application

From the project root:

```bash
docker compose --env-file backend/.env up --build -d
```

This starts:

- MySQL 8.4 on port `3306`.
- Rails API server on port `3000`.
- Streamlit frontend on port `8501`.

### 4. Create and migrate the database

```bash
docker compose exec backend bin/rails db:create db:migrate
```

### 5. Access the application

**Frontend:**

```text
http://localhost:8501
```

**Backend API:**

```text
http://localhost:3000
```

Health check endpoint:

```http
GET http://localhost:3000/api/v1/health
```

### 6. Run the test suites

**Backend RSpec tests:**

```bash
docker compose exec backend bundle exec rspec
```

**Frontend Pytest tests:**

From the frontend directory, activate the virtual environment and run:

```bash
python -m pytest
```

## Current Project Status

The core application MVP is implemented.

Implemented modules:

- Authentication and user management.
- Groups and memberships.
- Invitations.
- Expense management.
- Group and pairwise balance calculations.
- Settlement management and allocation tracking.
- Notifications.
- Streamlit frontend integration.
- Cursor-based pagination.
- Transactional and concurrency safeguards.
- Backend and frontend automated tests.

## Planned / Deferred

The following are outside the current MVP scope:

- Password change and password reset workflows.
- Account reactivation through a privileged super-admin workflow.
- Expense deletion and restoration.
- Group soft deletion and restoration.
- Automated audit logging.
- Background job processing using Sidekiq and Redis.
- Broader email and push notification workflows.

Registration verification and email-change verification emails are implemented. Broader notification delivery through email and push channels remains deferred.

## Future Development

Planned next steps include:

- Dedicated API documentation.
- Deployment and hosting configuration.
- Production environment setup.
- Deployment documentation.