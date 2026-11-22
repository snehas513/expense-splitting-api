# Expense Splitting API — Streamlit Frontend

A Streamlit frontend for the Rails Expense Splitting API.

## Requirements

- Python 3.10+
- The Rails API running locally on port 3000
- A verified user account

## Run locally

From this directory:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
streamlit run app.py
```

Open the URL printed by Streamlit (usually http://localhost:8501).

In the sidebar, set the Rails API base URL. If Streamlit is running on the same machine as Rails, use:

```text
http://localhost:3000
```

Log in with a verified account.

## Current implementation

- Login and registration requests
- Group selection
- Group members and roles
- Expense history and participant shares
- Group balances
- Settlement history
- Notifications and mark-as-read

The app deliberately delegates validation, authorization, balance calculations, and business rules to Rails.

## Next integration steps

The current first pass focuses on reading the API response formats supplied during development. Create/update actions (group creation, invitations, expenses, settlement requests and settlement decisions), profile management, and cursor pagination can be added after confirming their exact request payloads and response contracts.
