# Rails Model Associations

## 1. Overview

The Expense Splitting API uses nine database entities. Rails model associations define how these entities relate to each other and allow us to navigate relationships through ActiveRecord.

The main association types used are:

- `has_many` – one record can have multiple associated records.
- `belongs_to` – a record belongs to another record.
- `has_many :through` – access associated records through a join model.
- `polymorphic` – an association that can reference different model types.

## 2. User Model

A User can belong to multiple groups, participate in expenses, create expenses, pay expenses, send and receive settlements, and send or receive invitations.

```ruby
class User < ApplicationRecord
  has_many :memberships
  has_many :groups, through: :memberships

  has_many :notifications
  has_many :expense_participants
  has_many :audit_trails

  has_many :paid_expenses,
           class_name: "Expense",
           foreign_key: :paid_by_id

  has_many :created_expenses,
           class_name: "Expense",
           foreign_key: :created_by_id

  has_many :sent_settlements,
           class_name: "Settlement",
           foreign_key: :sender_id

  has_many :received_settlements,
           class_name: "Settlement",
           foreign_key: :receiver_id

  has_many :acted_on_settlements,
           class_name: "Settlement",
           foreign_key: :acted_by_id

  has_many :received_invitations,
           class_name: "Invitation",
           foreign_key: :invited_user_id

  has_many :sent_invitations,
           class_name: "Invitation",
           foreign_key: :invited_by_id
end
```

## 3. Group Model

A Group can have multiple memberships, expenses, settlements, and invitations.

Users can be accessed through memberships.

```ruby
class Group < ApplicationRecord
  has_many :memberships
  has_many :users, through: :memberships

  has_many :expenses
  has_many :settlements
  has_many :invitations
end
```

## 4. Membership Model

Membership connects a User with a Group.

```ruby
class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :group
end
```

Relationship:

- A User can have multiple Membership records.
- A Group can have multiple Membership records.
- Each Membership belongs to one User and one Group.

## 5. Invitation Model

An Invitation belongs to a Group and has two User relationships:

- The invited user.
- The user who sent the invitation.

```ruby
class Invitation < ApplicationRecord
  belongs_to :group

  belongs_to :invited_user,
             class_name: "User",
             foreign_key: :invited_user_id

  belongs_to :invited_by,
             class_name: "User",
             foreign_key: :invited_by_id
end
```

## 6. Expense Model

An Expense belongs to a Group and has two User relationships:

- Payer (`paid_by_id`).
- Creator (`created_by_id`).

An Expense can also have multiple participants through ExpenseParticipant.

```ruby
class Expense < ApplicationRecord
  belongs_to :group

  belongs_to :payer,
             class_name: "User",
             foreign_key: :paid_by_id

  belongs_to :creator,
             class_name: "User",
             foreign_key: :created_by_id

  has_many :expense_participants

  has_many :participants,
           through: :expense_participants,
           source: :user
end
```

## 7. ExpenseParticipant Model

ExpenseParticipant connects an Expense with a User and stores that participant's share amount.

```ruby
class ExpenseParticipant < ApplicationRecord
  belongs_to :user
  belongs_to :expense
end
```

The `participants` association on Expense uses this join model to access participating users directly.

## 8. Settlement Model

A Settlement belongs to a Group and has three User relationships:

- Sender (`sender_id`).
- Receiver (`receiver_id`).
- Actor (`acted_by_id`), who confirms, rejects, or cancels the settlement.

```ruby
class Settlement < ApplicationRecord
  belongs_to :group

  belongs_to :sender,
             class_name: "User",
             foreign_key: :sender_id

  belongs_to :receiver,
             class_name: "User",
             foreign_key: :receiver_id

  belongs_to :acted_by,
             class_name: "User",
             foreign_key: :acted_by_id,
             optional: true
end
```

The actor association is optional because a newly created pending settlement does not yet have an actor.

## 9. Notification Model

Each Notification belongs to one User.

```ruby
class Notification < ApplicationRecord
  belongs_to :user
end
```

A User can receive multiple notifications.

## 10. AuditTrail Model

AuditTrail records important actions performed in the application.

It has two associations:

- `user` – the actor who performed the action; optional for system-generated events.
- `auditable` – the affected record, which can belong to different model types.

```ruby
class AuditTrail < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :auditable, polymorphic: true
end
```

### Understanding Polymorphic Associations

The `auditable_type` and `auditable_id` columns together identify the affected record.

| auditable_type | auditable_id | Affected record |
|---|---:|---|
| Expense | 12 | Expense with ID 12 |
| Group | 5 | Group with ID 5 |
| User | 8 | User with ID 8 |
| Settlement | 21 | Settlement with ID 21 |

This allows one AuditTrail model to track changes across different entities without requiring separate foreign key columns for every model.

## 11. Important Association Concepts

### Custom class name and foreign key

When multiple associations point to the same model, we explicitly specify the model class and foreign key.

Example:

```ruby
belongs_to :payer,
           class_name: "User",
           foreign_key: :paid_by_id
```

Here:
- `payer` is the association name.
- `User` is the associated model.
- `paid_by_id` is the foreign key.

### Through association

A `has_many :through` association provides convenient access to records through a join model.

Example:

```ruby
has_many :participants,
         through: :expense_participants,
         source: :user
```

Here:
- `through` identifies the join model.
- `source` identifies the association inside that join model.

### Polymorphic association

A polymorphic association allows a model to belong to more than one model type using a shared pair of columns.

Example:

```ruby
belongs_to :auditable, polymorphic: true
```

## 12. Important Notes

- These associations describe relationships between Rails models; they do not replace database foreign keys.
- Custom foreign keys must match the actual database column names.
- `optional: true` allows a `belongs_to` association to be absent.
- The Group-to-User and Expense-to-Participant relationships use `has_many :through`.
- Settlement notifications do not currently have a direct database association because the notifications table does not contain a `settlement_id` column.
- Accessing `group.users` currently includes users associated through historical inactive memberships as well. Active-member filtering will be handled separately.

## 13. Current Status

All nine model files have been created or prepared, and their primary associations have been defined conceptually. The next development steps are to verify the associations in Rails, add validations, and write tests.