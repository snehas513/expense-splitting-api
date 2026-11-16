# Expense Splitting API

A backend application for managing shared expenses, tracking balances, and settling payments between members of a group.

## Project Overview

Expense Splitting API allows users to:

- Record shared expenses with equal splitting.
- Track individual balances within a group.
- View who owes whom.
- Create settlements between group members.
- Allocate settlements against one or more expenses.
- Confirm, reject, or cancel settlement requests.
- Maintain expense and settlement history.

## Technology Stack

- Ruby on Rails (API mode)
- Ruby
- MySQL
- Docker
- RSpec
- REST APIs

## Project Structure

- `backend/` - Rails API application
- `frontend/` - Streamlit frontend (planned)
- `docs/` - Project documentation

## Key Features

- JWT-based user authentication.
- Expense creation and equal-share calculation.
- Balance calculation based on expenses and confirmed settlements.
- Cursor-based pagination for expense and settlement listings.
- Settlement allocation across multiple expenses.
- Transactional settlement creation.
- Concurrency protection against over-allocation.
- Request, service, and model test coverage.

## Current Status

Backend API development is in progress.

Implemented:
- JWT-based authentication
- Expense creation and management
- Balance calculation
- Settlement lifecycle and expense allocations
- Cursor-based pagination
- Transactional settlement creation
- Concurrency protection against over-allocation

## Running the Project

Setup and execution instructions will be added as the backend setup is finalized.