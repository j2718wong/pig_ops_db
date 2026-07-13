# SuperPig: Relational Schema & Database Transactional Engine (`pig_ops_db`)

🔗 **Main System Repository:** [pig_ops](https://github.com)  
📊 **Database Core Context:** 80+ Relational Tables | 143 Stored Procedures | 30k+ Lines of Production SQL  
🏠 **Local Testing Target:** Verified compatibility with ARM64 architectures (Raspberry Pi Local Environment)

This repository serves as the high-integrity database core of the SuperPig ecosystem. Rather than pushing heavy computation loops to the application server layer, this architecture leverages raw database performance to enforce absolute transactional safety (ACID compliance) and data normalization.

---

### 📂 Repository Structure & Topography

```text
~/projects/jsys/pig_ops_db/
├── code_stats.sh*            # Project-wide metrics engine (Generates language/LOC audits)
├── migrate.sh*               # Continuous integration execution tool for schema state upgrades
├── execute_procedures.sh*    # Re-compilation tool compiling all procedures into the target DB
├── sync_db_local.sh*         # Automated downstream replication script (Prod Cloud ➔ Local Test Target)
├── sync_log.log              # State replication validation history log
│
├── deepseek/                 # AI-assisted prompt engineering files and schema context rules
└── database/mysql/
    ├── migrations/           # Sequential tracking of immutable structural DDL changes
    ├── procedures/           # Core transactional business logic modules (Stored Procedures)
    ├── prod_procs_call.sql   # Production execution footprints and testing orchestration hooks
    ├── str_csv.sql           # Specialized schema utility for high-velocity text/CSV importing
    ├── test.sql              # Ad-hoc development script verification sandbox
    ├── instructions.txt      # Engine execution parameters and developer directives
    └── not_used_anymore/     # Isolated legacy code archive
```

---

### ⚙️ Database Operations & Automation Framework

This layer is built for rapid development without losing transactional integrity. The key infrastructure scripts manage your lifecycle automation:

#### 🔄 1. Upstream-to-Downstream Replication (`sync_db_local.sh`)
To keep local environments entirely accurate without risking production uptime, executing `./sync_db_local.sh` safely replicates the production database down to the local environment. Output and errors are pipe-logged sequentially to `sync_log.log` for audit mapping.

#### 🗄️ 2. Schema State Management & Version Control (`migrate.sh`)
Database migrations are applied deterministically via `./migrate.sh`. It walks sequentially through the files stored in `database/mysql/migrations/`, ensuring incremental changes are executed atomically, keeping development and production structures aligned.

#### ⚡ 3. Stored Procedure Mass Compilations (`execute_procedures.sh`)
When deep core adjustments occur inside the `database/mysql/procedures/` directory, `./execute_procedures.sh` cycles through all 143 active routines. It flushes old execution trees and dynamically loads updated application layers directly into the target schema.

#### 📈 4. Automated Capability Audit Tracking (`code_stats.sh`)
To systematically analyze the health and volume of the multi-repo codebase, `./code_stats.sh` runs lines-of-code computations, tracking repository growth over time and breaking down architecture logic patterns by component type.

---

### 🛡️ Core Principles: High Relational Discipline

* **Database-Driven Safety:** Moving high-frequency livestock valuation loops, breeding calendars, and cost margins into isolated stored procedures prevents data race conditions and application-level transaction timeouts.
* **Pragmatic Testing Loop:** The dual-environment script ecosystem allows modifications to be written and checked down to a local layer before pushing migrations through server automation pipelines.

