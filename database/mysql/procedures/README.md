# Stored Procedures

This directory contains the transactional business logic of SuperPig.

All critical business operations — breeding, farrowing, weaning, feed
reconciliation, vaccinations, inventory, billing, and user onboarding —
are implemented as MySQL stored procedures rather than application-layer
services. Each procedure is a single ACID-compliant transaction that
updates every entity affected by the business event it represents.

This is a deliberate architectural choice. A single production event on a
pig farm mutates many interdependent records (production history, sow
status, boar status, farm statistics, cache version counters, and
relationship tables). Keeping the rules inside the database guarantees
that the same invariants hold regardless of which API endpoint triggers
the event.

For the reasoning behind this approach, see the case study in the
`pig_ops` repository.

---

## Layout

Procedures are grouped by the domain object they primarily operate on.
Most directories follow a consistent `add` / `update` / `delete` triad.

```
procedures/
|-- basic_user_check.sql          shared authorization primitive
|-- account/                      account lifecycle and onboarding
|-- account_pig_ops/              pig-operation fan-out (see below)
|-- account_sow_due_chklst/       sow due checklist operations
|-- billing/                      overdue checks and sow/boar counts
|-- feed_balance/                 feed inventory reconciliation
|-- feed_buy/                     feed purchase records
|-- pig_farm/                     farm configuration
|-- pig_farm_feed_buy/            per-farm feed purchases
|-- pig_farm_staff/               staff records
|-- pig_medvac/                   medication and vaccination
|-- pig_pen/                      pen assignment
|-- pig_prod_feed/                feed consumption per production
|-- pig_prod_notes/               notes attached to production
|-- pig_prod_pig_dead/            mortality records
|-- pig_prod_pig_ops/             pig operations per production
|-- pig_production/               core production lifecycle
|-- production_group/             grouping multiple productions
|-- production_harvest/           harvest and sale records
|-- sow_boar/                     sow and boar master records
|-- sow_boar_balance/             sow/boar counts per account
|-- user/                         registration, login, verification
`-- user_request/                 account join requests
```

---

## Where to Start Reading

If you want to understand how the system works, read these in order:

1. **`basic_user_check.sql`** — the shared authorization primitive
   called by every transactional procedure. Every transactional entry
   point begins here.

2. **`pig_production/pig_prod_add.sql`** — a complete breeding
   transaction. Updates production records, sow status, boar status,
   farm statistics, cache version counters, and relationship tables in
   a single atomic unit.

3. **`account_pig_ops/add/`** — the fan-out pattern. Adding a
   pig-operation record cascades into four downstream domains (gilts,
   gestating, lactating, weaning sows), each implemented as a separate
   coordinated procedure.

4. **`user/user_register_or_login.sql`** — the onboarding and
   authentication flow, supporting email signup, social login, and
   access-code based staff onboarding.

---

## Conventions

- **One operation, one transaction.** Each procedure wraps all of its
  writes in a single implicit transaction.
- **Explicit short-circuiting.** Errors set a `res_num` / `res_code` /
  `res_desc` triple and use `LEAVE <block_label>` to exit cleanly
  without committing partial work.
- **Version counters.** Every farm-level change increments one or more
  `data_ver_num_*` counters on `pig_farm`, which the mobile client uses
  to invalidate cached lists selectively instead of refetching
  everything.
- **Naming.** `<entity>_<operation>.sql`, e.g. `pig_pen_add.sql`,
  `user_update_login.sql`.

---

## Scale

- 143 procedures
- ~30,000 lines of SQL
- 80+ tables
- 69 migrations