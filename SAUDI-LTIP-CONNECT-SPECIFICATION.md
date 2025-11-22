# SAUDI-LTIP-CONNECT Platform
## Complete Technical Specification & System Architecture

**Version:** 1.0
**Date:** October 2025
**Target Market:** Publicly Listed Companies on Saudi Exchange (Tadawul)
**Scale:** Up to 50,000 employees per company account

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Architecture](#system-architecture)
3. [Database Schema Design](#database-schema-design)
4. [Module Specifications](#module-specifications)
5. [Security & Compliance](#security--compliance)
6. [Integration Requirements](#integration-requirements)
7. [Feature Roadmap](#feature-roadmap)
8. [Technical Stack](#technical-stack)

---

## Executive Summary

SAUDI-LTIP-CONNECT is a comprehensive SaaS platform designed to manage Long-Term Incentive Plans (LTIPs) and Employee Stock Option Plans (ESOPs) for publicly listed companies on the Saudi Exchange (Tadawul). The platform handles the complete lifecycle from plan creation, grant allocation, vesting tracking, to final share transfer to employee portfolios.

### Key Capabilities
- Multi-tenant architecture supporting 50,000+ employees per company
- Automated vesting calculation and share transfer engine
- CMA and Sharia compliance-ready workflows
- Real-time Tadawul market data integration
- Comprehensive audit trail for regulatory reporting
- Dual-language support (Arabic/English)

---

## System Architecture

### High-Level Architecture Diagram (Conceptual)

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                          │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐   │
│  │  Issuer Portal  │  │ Grantee Portal  │  │  Admin Portal   │   │
│  │   (Company)     │  │   (Employee)    │  │  (Super Admin)  │   │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘   │
│         React + TypeScript + Tailwind CSS                          │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        API GATEWAY LAYER                            │
├─────────────────────────────────────────────────────────────────────┤
│  Authentication │ Rate Limiting │ Request Validation │ Logging     │
│              Supabase Edge Functions (Deno)                         │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      APPLICATION LAYER                              │
├─────────────────────────────────────────────────────────────────────┤
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐         │
│  │   Company     │  │   Grant       │  │   Vesting     │         │
│  │   Management  │  │   Management  │  │   Engine      │         │
│  └───────────────┘  └───────────────┘  └───────────────┘         │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐         │
│  │   Portfolio   │  │   Document    │  │   Reporting   │         │
│  │   Management  │  │   Generation  │  │   & Analytics │         │
│  └───────────────┘  └───────────────┘  └───────────────┘         │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                                   │
├─────────────────────────────────────────────────────────────────────┤
│              Supabase PostgreSQL Database                           │
│  Row-Level Security (RLS) │ Audit Logs │ Encryption at Rest        │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    EXTERNAL INTEGRATIONS                            │
├─────────────────────────────────────────────────────────────────────┤
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐         │
│  │   Tadawul     │  │   Digital     │  │     HRIS      │         │
│  │   Market Data │  │   Signature   │  │  Integration  │         │
│  └───────────────┘  └───────────────┘  └───────────────┘         │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    BACKGROUND SERVICES                              │
├─────────────────────────────────────────────────────────────────────┤
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐         │
│  │   Vesting     │  │   Market Data │  │   Notification│         │
│  │   Scheduler   │  │   Sync Job    │  │   Service     │         │
│  │  (Daily Cron) │  │  (Real-time)  │  │   (Email/SMS) │         │
│  └───────────────┘  └───────────────┘  └───────────────┘         │
└─────────────────────────────────────────────────────────────────────┘
```

### Architecture Principles

1. **Multi-Tenancy**: Complete data isolation between companies using RLS
2. **Scalability**: Horizontal scaling for 50,000+ employees per tenant
3. **Security-First**: End-to-end encryption, MFA, audit trails
4. **Event-Driven**: Asynchronous processing for vesting and transfers
5. **API-First**: RESTful APIs for all integrations
6. **Compliance-Ready**: Immutable audit logs, data residency in KSA

---

## Database Schema Design

### Core Tables Structure

#### 1. Companies (Issuers)
```sql
companies
├── id (uuid, PK)
├── company_name_en (text)
├── company_name_ar (text)
├── tadawul_symbol (text, unique)
├── commercial_registration_number (text, unique)
├── verification_status (enum: pending, verified, rejected)
├── verification_documents (jsonb)
├── reserved_portfolio_id (uuid, FK -> portfolios)
├── total_reserved_shares (numeric)
├── available_shares (numeric)
├── admin_user_id (uuid, FK -> auth.users)
├── status (enum: active, suspended, inactive)
├── created_at (timestamptz)
├── updated_at (timestamptz)
└── metadata (jsonb)
```

#### 2. Company Users & Roles
```sql
company_users
├── id (uuid, PK)
├── company_id (uuid, FK -> companies)
├── user_id (uuid, FK -> auth.users)
├── role (enum: super_admin, hr_admin, finance_admin, legal_admin, viewer)
├── permissions (jsonb)
├── is_active (boolean)
├── created_at (timestamptz)
└── last_login_at (timestamptz)
```

#### 3. Employees (Grantees)
```sql
employees
├── id (uuid, PK)
├── company_id (uuid, FK -> companies)
├── employee_number (text)
├── national_id (text, encrypted)
├── email (text)
├── phone (text)
├── first_name_en (text)
├── last_name_en (text)
├── first_name_ar (text)
├── last_name_ar (text)
├── department (text)
├── job_title (text)
├── hire_date (date)
├── employment_status (enum: active, terminated, resigned, retired)
├── termination_date (date)
├── vested_portfolio_id (uuid, FK -> portfolios)
├── user_id (uuid, FK -> auth.users, nullable)
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

#### 4. LTIP/ESOP Plans
```sql
incentive_plans
├── id (uuid, PK)
├── company_id (uuid, FK -> companies)
├── plan_name_en (text)
├── plan_name_ar (text)
├── plan_type (enum: LTIP_RSU, LTIP_RSA, ESOP)
├── plan_code (text, unique per company)
├── description_en (text)
├── description_ar (text)
├── vesting_schedule_type (enum: time_based, performance_based, hybrid)
├── vesting_config (jsonb)
│   ├── duration_months
│   ├── cliff_months
│   ├── vesting_frequency (monthly, quarterly, annual)
│   └── performance_metrics (if applicable)
├── exercise_price (numeric, for ESOP)
├── total_shares_allocated (numeric)
├── shares_granted (numeric)
├── shares_available (numeric)
├── start_date (date)
├── end_date (date)
├── status (enum: draft, active, closed, suspended)
├── approval_status (enum: pending, approved, rejected)
├── approved_by (uuid, FK -> company_users)
├── approved_at (timestamptz)
├── created_by (uuid, FK -> company_users)
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

#### 5. Grants (Individual Allocations)
```sql
grants
├── id (uuid, PK)
├── grant_number (text, unique)
├── company_id (uuid, FK -> companies)
├── plan_id (uuid, FK -> incentive_plans)
├── employee_id (uuid, FK -> employees)
├── grant_date (date)
├── total_shares (numeric)
├── vested_shares (numeric)
├── exercised_shares (numeric, for ESOP)
├── forfeited_shares (numeric)
├── remaining_unvested_shares (numeric)
├── vesting_start_date (date)
├── vesting_end_date (date)
├── contract_document_url (text)
├── contract_signed_at (timestamptz)
├── employee_acceptance_at (timestamptz)
├── status (enum: pending_signature, active, completed, forfeited, cancelled)
├── cancellation_reason (text)
├── created_by (uuid, FK -> company_users)
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

#### 6. Vesting Schedule (Detailed Tracking)
```sql
vesting_schedules
├── id (uuid, PK)
├── grant_id (uuid, FK -> grants)
├── sequence_number (integer)
├── vesting_date (date)
├── shares_to_vest (numeric)
├── performance_condition_met (boolean)
├── performance_metrics (jsonb)
├── actual_vest_date (date)
├── status (enum: pending, vested, forfeited)
├── processed_at (timestamptz)
└── created_at (timestamptz)
```

#### 7. Portfolios (Share Custody)
```sql
portfolios
├── id (uuid, PK)
├── portfolio_type (enum: company_reserved, employee_vested)
├── company_id (uuid, FK -> companies)
├── employee_id (uuid, FK -> employees, nullable)
├── total_shares (numeric)
├── available_shares (numeric)
├── locked_shares (numeric)
├── portfolio_number (text, unique)
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

#### 8. Share Transfers (Custody Movements)
```sql
share_transfers
├── id (uuid, PK)
├── transfer_number (text, unique)
├── company_id (uuid, FK -> companies)
├── grant_id (uuid, FK -> grants)
├── employee_id (uuid, FK -> employees)
├── from_portfolio_id (uuid, FK -> portfolios)
├── to_portfolio_id (uuid, FK -> portfolios)
├── shares_transferred (numeric)
├── transfer_type (enum: vesting, forfeiture, exercise, cancellation)
├── transfer_date (date)
├── market_price_at_transfer (numeric)
├── processed_at (timestamptz)
├── processed_by_system (boolean)
├── notes (text)
└── created_at (timestamptz)
```

#### 9. Market Data Cache
```sql
market_data
├── id (uuid, PK)
├── tadawul_symbol (text)
├── trading_date (date)
├── opening_price (numeric)
├── closing_price (numeric)
├── high_price (numeric)
├── low_price (numeric)
├── volume (bigint)
├── last_updated (timestamptz)
└── source (text)
```

#### 10. Audit Trail
```sql
audit_logs
├── id (uuid, PK)
├── company_id (uuid, FK -> companies)
├── user_id (uuid, FK -> auth.users)
├── entity_type (text)
├── entity_id (uuid)
├── action (text)
├── old_values (jsonb)
├── new_values (jsonb)
├── ip_address (inet)
├── user_agent (text)
├── timestamp (timestamptz)
└── metadata (jsonb)
```

#### 11. Document Storage
```sql
documents
├── id (uuid, PK)
├── company_id (uuid, FK -> companies)
├── document_type (enum: contract, verification, certificate, report)
├── related_entity_type (text)
├── related_entity_id (uuid)
├── file_name (text)
├── file_size (bigint)
├── storage_path (text)
├── mime_type (text)
├── language (enum: en, ar)
├── is_signed (boolean)
├── signature_data (jsonb)
├── uploaded_by (uuid, FK -> auth.users)
├── uploaded_at (timestamptz)
└── expires_at (timestamptz)
```

#### 12. Notifications
```sql
notifications
├── id (uuid, PK)
├── company_id (uuid, FK -> companies)
├── recipient_user_id (uuid, FK -> auth.users)
├── notification_type (enum: grant_issued, vesting_completed, document_ready)
├── title_en (text)
├── title_ar (text)
├── message_en (text)
├── message_ar (text)
├── priority (enum: low, medium, high, urgent)
├── read_at (timestamptz)
├── delivery_channels (text[])
├── delivery_status (jsonb)
├── created_at (timestamptz)
└── expires_at (timestamptz)
```

### Indexes & Performance Optimization

```sql
-- Critical indexes for performance at scale
CREATE INDEX idx_employees_company ON employees(company_id) WHERE employment_status = 'active';
CREATE INDEX idx_grants_employee ON grants(employee_id) WHERE status = 'active';
CREATE INDEX idx_vesting_schedules_date ON vesting_schedules(vesting_date) WHERE status = 'pending';
CREATE INDEX idx_transfers_company_date ON share_transfers(company_id, transfer_date DESC);
CREATE INDEX idx_audit_logs_company_timestamp ON audit_logs(company_id, timestamp DESC);
CREATE INDEX idx_market_data_symbol_date ON market_data(tadawul_symbol, trading_date DESC);
```

---

## Module Specifications

### Module 1: Company Onboarding & Administration

#### 1.1 Secure Onboarding Flow

**Step 1: Company Registration**
- Input: Commercial Registration Number, Tadawul Symbol
- Validation: Real-time verification against Tadawul listed companies registry
- Document Upload: CR certificate, Board resolution authorizing LTIP/ESOP program
- Primary Administrator Setup: National ID, email, phone with OTP verification

**Step 2: Verification Process**
- Manual review by platform administrators
- Document authenticity checks
- Approval workflow (approve/reject with notes)
- Automated notification upon approval

**Step 3: Reserved Portfolio Creation**
- Automatic generation of unique portfolio identifier
- Initial share reservation input
- Blockchain-style transaction recording for immutability

#### 1.2 Role-Based Access Control (RBAC)

**Permission Matrix:**

| Role          | View Plans | Create Plans | Grant Shares | View All Employees | Export Data | Approve Plans |
|---------------|------------|--------------|--------------|-----------------------|-------------|---------------|
| Super Admin   | ✓          | ✓            | ✓            | ✓                     | ✓           | ✓             |
| HR Admin      | ✓          | ✓            | ✓            | ✓                     | ✓           | ✗             |
| Finance Admin | ✓          | ✓            | ✗            | ✓                     | ✓           | ✓             |
| Legal Admin   | ✓          | ✗            | ✗            | ✗                     | ✗           | ✓             |
| Viewer        | ✓          | ✗            | ✗            | ✗                     | ✗           | ✗             |

**Implementation:**
- PostgreSQL RLS policies per role
- JWT token claims for role validation
- UI elements conditionally rendered based on permissions

#### 1.3 Employee Data Management

**Bulk Import:**
- CSV template with required fields (Employee Number, National ID, Name EN/AR, Email, Department, Hire Date)
- Validation rules: Duplicate detection, format checks, required field validation
- Preview before commit with error reporting
- Transaction-based import (all-or-nothing)

**Individual Management:**
- CRUD operations with audit trail
- Search and filter by department, hire date, status
- Pagination for 50,000+ records using cursor-based approach
- Export functionality with data masking for sensitive fields

---

### Module 2: LTIP/ESOP Contract Management & Issuance

#### 2.1 Plan Definition Engine

**Plan Configuration Interface:**

**Time-Based Vesting Example:**
```json
{
  "vesting_schedule_type": "time_based",
  "duration_months": 48,
  "cliff_months": 12,
  "vesting_frequency": "monthly",
  "vesting_increments": [
    {"month": 12, "percentage": 25},
    {"month": 24, "percentage": 25},
    {"month": 36, "percentage": 25},
    {"month": 48, "percentage": 25}
  ]
}
```

**Performance-Based Vesting Example:**
```json
{
  "vesting_schedule_type": "performance_based",
  "duration_months": 36,
  "performance_metrics": [
    {
      "metric_name": "Revenue Growth",
      "target": "15%",
      "weight": 0.5
    },
    {
      "metric_name": "EBITDA Margin",
      "target": "20%",
      "weight": 0.5
    }
  ],
  "achievement_thresholds": [
    {"achievement": "100%", "vesting_percentage": 100},
    {"achievement": "80-99%", "vesting_percentage": 80},
    {"achievement": "<80%", "vesting_percentage": 0}
  ]
}
```

**Hybrid Vesting Example:**
```json
{
  "vesting_schedule_type": "hybrid",
  "time_component": {
    "duration_months": 36,
    "cliff_months": 12,
    "time_weight": 0.6
  },
  "performance_component": {
    "metrics": [...],
    "performance_weight": 0.4
  }
}
```

#### 2.2 Grant Allocation & Contract Generation

**Batch Issuance Process:**

1. **Selection Phase:**
   - Filter employees by criteria (department, hire date, job level)
   - Manual selection or criteria-based auto-selection
   - Preview total shares to be granted vs. available pool

2. **Allocation Phase:**
   - Distribute shares equally or by formula (e.g., percentage of salary, job level multiplier)
   - Real-time validation against available pool
   - Conflict detection (existing active grants check)

3. **Contract Generation:**
   - Template selection (LTIP RSU/RSA, ESOP)
   - Mail merge with employee data, grant details, vesting schedule
   - PDF generation in both Arabic and English
   - Legal disclaimer and terms auto-populated

4. **Distribution:**
   - Store contracts in secure document repository
   - Send notification to employees with secure login link
   - Track contract delivery status

#### 2.3 Digital Signature Integration

**Signature Workflow:**

1. Company signatory signs first (authorized representative)
2. Contract status: `pending_employee_signature`
3. Employee receives notification with secure link
4. Employee reviews and signs using certified e-signature provider
5. Both signatures verified and timestamped
6. Final signed document stored immutably
7. Grant status changes to `active`

**Integration Partners (KSA-Certified):**
- Yesser e-Signature
- ZATCA-approved digital signature providers
- Fallback: Manual signature upload with OCR verification

---

### Module 3: Safekeeping, Vesting & Transfer Logic

#### 3.1 Share Safekeeping Architecture

**Portfolio Structure:**

```
Company: ACME Corp (Tadawul: 1234)
├── Reserved Portfolio (ID: RP-1234-001)
│   ├── Total Shares: 1,000,000
│   ├── Granted (Locked): 750,000
│   └── Available: 250,000
│
└── Employee Vested Portfolios
    ├── Ahmed Al-Farsi (ID: EVP-1234-00001)
    │   └── Vested Shares: 1,000
    ├── Fatima Al-Qahtani (ID: EVP-1234-00002)
    │   └── Vested Shares: 1,500
    └── ... (50,000 portfolios)
```

**Share State Machine:**

```
Company Treasury
     ↓
[Reserved Portfolio] ← Shares allocated to LTIP/ESOP pool
     ↓
[Granted but Unvested] ← Locked to specific employee grants
     ↓
[Vesting Completed] ← Automated daily vesting service
     ↓
[Employee Vested Portfolio] ← Available for future sale/exercise
     ↓
[Exercised/Sold] ← (Future: Broker integration)
```

#### 3.2 Automated Vesting Service

**Daily Vesting Job (Scheduled Function):**

```typescript
// Pseudocode for vesting engine
async function dailyVestingJob() {
  const today = new Date();

  // Step 1: Fetch all pending vesting schedules for today
  const pendingVestings = await db.vesting_schedules
    .where('vesting_date', '<=', today)
    .where('status', '=', 'pending');

  for (const vesting of pendingVestings) {
    const grant = await db.grants.findById(vesting.grant_id);
    const employee = await db.employees.findById(grant.employee_id);

    // Step 2: Check employment status
    if (employee.employment_status !== 'active') {
      await forfeitVesting(vesting, grant);
      continue;
    }

    // Step 3: Check performance conditions (if applicable)
    if (vesting.performance_condition_required) {
      const conditionMet = await evaluatePerformanceCondition(vesting);
      if (!conditionMet) {
        await db.vesting_schedules.update(vesting.id, {
          status: 'forfeited',
          notes: 'Performance condition not met'
        });
        continue;
      }
    }

    // Step 4: Execute share transfer
    await transferShares({
      from_portfolio: grant.company.reserved_portfolio_id,
      to_portfolio: employee.vested_portfolio_id,
      shares: vesting.shares_to_vest,
      grant_id: grant.id,
      transfer_type: 'vesting',
      market_price: await getCurrentMarketPrice(grant.company.tadawul_symbol)
    });

    // Step 5: Update records
    await db.vesting_schedules.update(vesting.id, {
      status: 'vested',
      actual_vest_date: today,
      processed_at: new Date()
    });

    await db.grants.update(grant.id, {
      vested_shares: grant.vested_shares + vesting.shares_to_vest,
      remaining_unvested_shares: grant.remaining_unvested_shares - vesting.shares_to_vest
    });

    // Step 6: Send notification
    await sendVestingNotification(employee, vesting.shares_to_vest);

    // Step 7: Log audit trail
    await logAuditEvent({
      action: 'VESTING_COMPLETED',
      entity: 'grant',
      entity_id: grant.id,
      details: {
        shares_vested: vesting.shares_to_vest,
        total_vested: grant.vested_shares + vesting.shares_to_vest
      }
    });
  }
}
```

**Scheduling:**
- Runs daily at 00:00 UTC+3 (Riyadh time)
- Implemented as Supabase Edge Function with pg_cron trigger
- Idempotency ensured via transaction locks
- Retry mechanism for failed transfers
- Alert system for administrators on failures

#### 3.3 Post-Vesting Transfer

**Transfer Execution:**

```sql
-- Atomic transfer transaction
BEGIN;

-- Lock portfolios to prevent race conditions
SELECT * FROM portfolios
WHERE id IN (from_portfolio_id, to_portfolio_id)
FOR UPDATE;

-- Deduct from company reserved portfolio
UPDATE portfolios
SET available_shares = available_shares - shares_transferred,
    updated_at = NOW()
WHERE id = from_portfolio_id;

-- Add to employee vested portfolio
UPDATE portfolios
SET total_shares = total_shares + shares_transferred,
    available_shares = available_shares + shares_transferred,
    updated_at = NOW()
WHERE id = to_portfolio_id;

-- Record transfer
INSERT INTO share_transfers (
  transfer_number, company_id, grant_id, employee_id,
  from_portfolio_id, to_portfolio_id, shares_transferred,
  transfer_type, transfer_date, market_price_at_transfer,
  processed_at, processed_by_system
) VALUES (...);

COMMIT;
```

**Rollback Scenarios:**
- Insufficient shares in reserved portfolio (should never happen if logic is correct)
- Portfolio locked by another transaction
- Database constraint violation
- All scenarios trigger automatic rollback and admin alert

#### 3.4 Termination/Forfeiture Handling

**Automated Forfeiture Process:**

1. **Trigger Event:** Employee status changed to `terminated`, `resigned`, or `retired`
2. **Immediate Actions:**
   - Fetch all active grants for employee
   - Identify all unvested vesting schedules
   - Mark all unvested schedules as `forfeited`
3. **Share Repatriation:**
   - Calculate total unvested shares across all grants
   - Transfer shares back to company reserved portfolio
   - Record forfeiture transfer with reason
4. **Grant Finalization:**
   - Update grant status to `completed` or `forfeited` (if no shares vested)
   - Lock grant record (no further modifications allowed)
5. **Notifications:**
   - HR admin notified of forfeiture
   - Employee receives final vesting summary
6. **Audit Trail:**
   - Immutable log entry created with termination date, forfeited shares, reason

**Special Cases:**
- Good Leaver Clause: Configuration to allow accelerated vesting
- Bad Leaver Clause: Immediate forfeiture including vested but unexercised shares (for ESOP)
- Partial Vesting on Termination: Pro-rated vesting based on months served

---

### Module 4: Employee Experience (Grantee Portal)

#### 4.1 Personal Dashboard

**Dashboard Widgets:**

1. **Portfolio Summary Card**
   - Total Shares Granted
   - Vested Shares (Available)
   - Unvested Shares (Pending)
   - Total Estimated Value (Current Market Price)

2. **Next Vesting Milestone**
   - Date of next vesting event
   - Number of shares vesting
   - Countdown timer
   - Motivational progress bar

3. **Active Grants List**
   - Grant number, plan name, grant date
   - Quick view of vesting progress
   - Link to full grant details

4. **Recent Activity Feed**
   - Vesting events (shares transferred)
   - New grants issued
   - Document uploads

#### 4.2 Vesting Visualization

**Interactive Timeline Component:**

```
[Grant Start]──────●────●────●────●────[Grant End]
               12mo  24mo  36mo  48mo
                ↓     ↓     ↓     ↓
              25%   25%   25%   25%
            (Vested)(Next)(Pending)(Pending)
```

**Vesting Progress Graph:**
- Line chart showing cumulative vested shares over time
- Shaded area for unvested future vestings
- Markers for completed vesting events
- Projected future value based on current share price

**Data Table View:**

| Vesting Date | Shares | Status    | Market Price | Value     |
|--------------|--------|-----------|--------------|-----------|
| 2024-01-15   | 250    | Vested    | SAR 125.50   | SAR 31,375|
| 2025-01-15   | 250    | Vested    | SAR 138.20   | SAR 34,550|
| 2026-01-15   | 250    | Pending   | -            | -         |
| 2027-01-15   | 250    | Pending   | -            | -         |

#### 4.3 Valuation Reporting

**Real-Time Market Integration:**

- Display current Tadawul price (15-minute delayed for free tier, real-time for premium)
- Historical price chart for company stock
- Calculate and display:
  - Total Vested Value: `vested_shares × current_price`
  - Total Potential Value: `(vested + unvested) × current_price`
  - Gain/Loss vs. Grant Price: For ESOP, show spread

**Motivational Elements:**
- "Your shares have increased by 23% since grant date"
- "You're 50% vested in your journey to full ownership"
- Gamification: Vesting streaks, milestones achieved

#### 4.4 Document Access

**Document Library:**
- Grant Contracts (signed PDFs)
- Annual Vesting Statements
- Tax Forms (if applicable)
- Plan Documents and Terms & Conditions
- One-click download with watermarking (employee name, download date)

---

## Security & Compliance

### 5.1 Security Architecture

#### Authentication & Authorization

**Multi-Factor Authentication (MFA):**
- Mandatory for all company administrators
- Optional but encouraged for employees
- Supported methods: SMS OTP, Email OTP, Authenticator App (TOTP)

**Session Management:**
- JWT tokens with 1-hour expiration
- Refresh tokens valid for 30 days
- Automatic logout after 15 minutes of inactivity
- Device fingerprinting for suspicious login detection

**Password Policy:**
- Minimum 12 characters
- Mix of uppercase, lowercase, numbers, special characters
- Password history (cannot reuse last 5 passwords)
- Password expiry after 90 days for admins

#### Data Encryption

**Encryption at Rest:**
- Database: AES-256 encryption for all tables
- File Storage: Server-side encryption for documents
- Sensitive Fields: Additional field-level encryption for National IDs, bank accounts

**Encryption in Transit:**
- TLS 1.3 for all API communications
- Certificate pinning for mobile apps
- Secure WebSocket connections for real-time updates

**Key Management:**
- Keys stored in dedicated Key Management Service (KMS)
- Automatic key rotation every 90 days
- Separate keys per environment (dev, staging, production)

#### Row-Level Security (RLS) Policies

**Company Data Isolation:**
```sql
-- Companies can only see their own data
CREATE POLICY "Company users see own company data"
ON companies FOR SELECT
TO authenticated
USING (
  id IN (
    SELECT company_id FROM company_users
    WHERE user_id = auth.uid()
  )
);
```

**Employee Data Access:**
```sql
-- Employees can only see their own records
CREATE POLICY "Employees view own data"
ON employees FOR SELECT
TO authenticated
USING (
  user_id = auth.uid()
  OR
  company_id IN (
    SELECT company_id FROM company_users
    WHERE user_id = auth.uid()
    AND role IN ('super_admin', 'hr_admin', 'finance_admin')
  )
);
```

**Grant Data Protection:**
```sql
-- Grants accessible only to employee or company admins
CREATE POLICY "Grant access control"
ON grants FOR SELECT
TO authenticated
USING (
  employee_id IN (
    SELECT id FROM employees WHERE user_id = auth.uid()
  )
  OR
  company_id IN (
    SELECT company_id FROM company_users
    WHERE user_id = auth.uid()
    AND role IN ('super_admin', 'hr_admin', 'finance_admin')
  )
);
```

### 5.2 Compliance Framework

#### CMA (Capital Market Authority) Compliance

**Regulatory Requirements:**
1. **Disclosure Requirements:**
   - Maintain records of all LTIP/ESOP grants for 10 years
   - Quarterly reporting of total shares under LTIP/ESOP programs
   - Immediate disclosure of material changes to plans

2. **Trading Restrictions:**
   - Blackout period enforcement for insiders
   - Pre-clearance workflow for employees with material non-public information
   - Integration with company's insider trading policy

3. **Market Abuse Prevention:**
   - Automated alerts for unusual vesting or exercise patterns
   - Mandatory holding periods post-vesting (configurable)
   - Audit trail for all share movements

#### Sharia Compliance Considerations

**Halal Investment Structure:**
- Ensure company shares are Sharia-compliant (no investment in prohibited sectors)
- Interest-free financing options for ESOP exercise
- Zakat calculation assistance for vested shares

**Documentation:**
- Sharia certification from approved scholars
- Arabic-first language for all legal documents
- Compliance attestation in annual reports

#### Data Residency & Privacy

**KSA Data Localization:**
- All production databases hosted in AWS/Azure Middle East (Bahrain) region
- Data replication within KSA/GCC only
- No cross-border data transfers without explicit consent

**GDPR-Aligned Privacy (Where Applicable):**
- Right to access: Employees can download all their data
- Right to rectification: Self-service data correction
- Right to erasure: Data anonymization post-termination (retain audit logs)
- Data minimization: Collect only necessary information

#### Audit Trail Requirements

**Immutable Logging:**
- Every CREATE, UPDATE, DELETE operation logged
- Logs include: timestamp, user, IP address, old/new values
- Logs cannot be modified or deleted (append-only table)
- Automated backup to separate audit log database

**Compliance Reports:**
- Pre-built reports for CMA submission
- Quarterly grant activity summary
- Annual vesting and forfeiture statistics
- On-demand audit trail exports for specific entities

---

## Integration Requirements

### 6.1 Tadawul Market Data Integration

**Data Requirements:**
- Real-time or 15-minute delayed stock prices
- Daily OHLC (Open, High, Low, Close) data
- Trading volume
- Corporate actions (splits, dividends)

**Integration Approach:**

**Option 1: Direct API Integration**
- Partner: Mubasher, Argaam, or Tadawul official data feed
- Frequency: Real-time WebSocket or polling every 5 minutes
- Fallback: Daily batch update at market close

**Option 2: Third-Party Data Provider**
- Partner: Bloomberg API, Refinitiv
- Benefits: Historical data, analytics, multi-market support
- Cost: Higher but comprehensive

**Implementation:**
```typescript
// Edge Function: Sync Market Data
async function syncMarketData(tadawul_symbol: string) {
  const response = await fetch(
    `https://api.tadawul-data-provider.com/v1/stocks/${tadawul_symbol}/quote`,
    {
      headers: {
        'Authorization': `Bearer ${process.env.TADAWUL_API_KEY}`
      }
    }
  );

  const quoteData = await response.json();

  await supabase.from('market_data').upsert({
    tadawul_symbol,
    trading_date: quoteData.date,
    opening_price: quoteData.open,
    closing_price: quoteData.close,
    high_price: quoteData.high,
    low_price: quoteData.low,
    volume: quoteData.volume,
    last_updated: new Date().toISOString(),
    source: 'Tadawul Official API'
  });
}
```

**Caching Strategy:**
- Cache prices for 5 minutes for real-time tier
- Cache daily close price indefinitely
- Invalidate cache on corporate actions

### 6.2 HRIS/Payroll Integration

**Integration Points:**

1. **Employee Data Sync:**
   - Bi-directional sync of employee master data
   - Fields: Employee ID, Name, Department, Job Title, Hire Date, Status
   - Frequency: Daily batch sync + real-time webhooks for critical changes (terminations)

2. **Org Structure Sync:**
   - Department hierarchy
   - Manager-employee relationships
   - Used for approval workflows

3. **Payroll Integration (Future):**
   - Tax withholding on vested shares
   - ESOP exercise deductions from payroll
   - W-2/tax form data export

**Supported HRIS Systems:**
- SAP SuccessFactors (common in KSA enterprises)
- Oracle HCM Cloud
- Workday (for multinational subsidiaries)
- Local providers: GOSI integration for validation

**API Architecture:**
```
SAUDI-LTIP-CONNECT               HRIS System
       │                              │
       │◄─────── Webhook ─────────────┤ (Employee Terminated)
       │                              │
       ├─── GET /api/v1/employees ───►│ (Daily Sync)
       │                              │
       │◄──── Employee Data ──────────┤
       │                              │
       ├── POST /api/v1/validate ────►│ (Real-time validation)
       │                              │
```

**Security:**
- Mutual TLS authentication
- API key rotation every 90 days
- IP whitelisting
- Request signing for integrity

### 6.3 Digital Signature Integration

**Certified Providers (KSA):**

**Primary: Yesser e-Signature**
- Government-approved PKI infrastructure
- Integration via REST API
- Supports both Arabic and English documents
- Legal validity under Saudi eSignature Law

**Implementation Flow:**
1. Generate PDF contract in platform
2. Upload to Yesser API with signer metadata
3. Receive signing URL
4. Embed URL in employee notification email
5. Yesser webhooks notify platform on signature completion
6. Download signed PDF with embedded certificate
7. Store in immutable document repository

**Fallback: Manual Upload**
- If employee cannot use e-signature (accessibility, preference)
- Upload scanned signed document
- OCR verification of signature fields
- Manual review by HR admin

### 6.4 Notification Service Integration

**Channels:**
1. **Email:** Transactional emails via SendGrid or AWS SES
2. **SMS:** Twilio or local provider (STC, Mobily) for OTP and critical alerts
3. **In-App:** Real-time notifications via WebSocket (Supabase Realtime)
4. **Push Notifications:** For mobile app (future)

**Notification Types:**

| Event                  | Channel      | Priority | Arabic/English |
|------------------------|--------------|----------|----------------|
| Grant Issued           | Email, In-App| Medium   | Both           |
| Contract Ready to Sign | Email, SMS   | High     | Both           |
| Vesting Completed      | Email, In-App| High     | Both           |
| Termination Processed  | Email        | Urgent   | Both           |
| MFA Code               | SMS, Email   | Urgent   | English        |

**Template Management:**
- Separate templates for Arabic and English
- Variable substitution using Handlebars
- Preview mode for testing
- A/B testing capability for engagement optimization

---

## Feature Roadmap

### Phase 1: MVP (Months 1-3)

**Core Infrastructure:**
- ✓ Database schema implementation
- ✓ Authentication system with MFA
- ✓ Company onboarding workflow
- ✓ Employee data management (bulk import + CRUD)

**Essential Modules:**
- ✓ LTIP/ESOP plan definition (time-based vesting only)
- ✓ Grant allocation and contract generation
- ✓ Basic portfolio management
- ✓ Automated daily vesting service
- ✓ Employee portal (dashboard + vesting timeline)

**Integrations:**
- ✓ Static market data (daily batch update)
- ✓ Email notifications

**Deliverable:** Working platform for 1 pilot company with up to 1,000 employees

### Phase 2: Enhanced Features (Months 4-6)

**Advanced Vesting:**
- ✓ Performance-based vesting support
- ✓ Hybrid vesting models
- ✓ Custom vesting schedule builder

**Compliance & Reporting:**
- ✓ Comprehensive audit trail UI
- ✓ CMA compliance report generator
- ✓ Export functionality (PDF, Excel)

**User Experience:**
- ✓ Arabic language UI (full translation)
- ✓ Mobile-responsive design optimization
- ✓ Interactive data visualizations

**Integrations:**
- ✓ Digital signature integration (Yesser)
- ✓ Real-time market data (WebSocket)
- ✓ SMS notifications

**Deliverable:** Production-ready platform for 5-10 companies

### Phase 3: Scale & Optimization (Months 7-9)

**Performance:**
- ✓ Database query optimization for 50,000+ employees
- ✓ Caching layer (Redis) for frequently accessed data
- ✓ Async job processing for bulk operations

**HRIS Integration:**
- ✓ SAP SuccessFactors connector
- ✓ Oracle HCM connector
- ✓ Generic REST API adapter for custom systems

**Advanced Features:**
- ✓ Termination/forfeiture automation
- ✓ Good/bad leaver clause configuration
- ✓ Multi-plan grants per employee
- ✓ Grant modification and amendment workflows

**Administration:**
- ✓ Super admin portal for platform management
- ✓ Multi-company analytics dashboard
- ✓ System health monitoring

**Deliverable:** Platform supporting 20+ companies, 500,000+ total employees

### Phase 4: Advanced Features (Months 10-12)

**Financial Features:**
- ✓ ESOP exercise workflow
- ✓ Broker integration for share sale
- ✓ Tax calculation and reporting
- ✓ Payment gateway for exercise price payment

**Analytics & Insights:**
- ✓ Predictive analytics (vesting forecasts, forfeiture predictions)
- ✓ Benchmarking against industry standards
- ✓ ROI calculator for companies
- ✓ Employee engagement scoring

**Sharia Compliance:**
- ✓ Sharia-compliant investment verification
- ✓ Zakat calculator for employees
- ✓ Islamic financing options for ESOP exercise

**Mobile App:**
- ✓ Native iOS and Android apps
- ✓ Biometric authentication
- ✓ Push notifications

**Deliverable:** Comprehensive platform with unique competitive advantages

### Phase 5: Market Expansion (Year 2)

**Regional Expansion:**
- ✓ Support for UAE DFM/ADX listed companies
- ✓ Kuwait Boursa integration
- ✓ Qatar Stock Exchange integration

**Enterprise Features:**
- ✓ White-label solution for large enterprises
- ✓ On-premise deployment option
- ✓ Advanced customization and theming

**AI & Automation:**
- ✓ AI-powered plan recommendation engine
- ✓ Predictive forfeiture alerts
- ✓ Automated compliance checking with ML

**Deliverable:** Regional market leader in GCC LTIP/ESOP management

---

## Technical Stack

### Frontend Stack

**Core Framework:**
- React 18.3+ with TypeScript 5.5+
- Vite for build tooling and development server
- React Router for navigation

**UI & Styling:**
- Tailwind CSS 3.4+ for utility-first styling
- Lucide React for iconography
- Recharts for data visualization
- Framer Motion for animations

**State Management:**
- React Context for global state
- TanStack Query for server state management
- Zustand for client state (if needed)

**Forms & Validation:**
- React Hook Form for complex forms
- Zod for schema validation

**Internationalization:**
- react-i18next for Arabic/English support
- RTL (Right-to-Left) layout support

### Backend Stack

**Database:**
- Supabase PostgreSQL (14+)
- PostGIS extension for geolocation features (if needed)
- pg_cron for scheduled jobs

**API Layer:**
- Supabase Edge Functions (Deno runtime)
- RESTful API design
- Supabase Realtime for WebSocket connections

**Authentication:**
- Supabase Auth with email/password
- JWT tokens with custom claims
- MFA via Supabase Auth (TOTP, SMS)

**Storage:**
- Supabase Storage for document files
- Bucket policies for access control
- CDN for static assets

### Infrastructure

**Hosting:**
- Supabase Cloud (Middle East region preferred)
- Fallback: AWS Middle East (Bahrain) or Azure UAE
- CDN: Cloudflare for global distribution

**CI/CD:**
- GitHub Actions for automated testing and deployment
- Staged deployments: Dev → Staging → Production
- Automated database migrations

**Monitoring & Logging:**
- Supabase Dashboard for database metrics
- Sentry for error tracking
- LogRocket or FullStory for session replay
- Uptime monitoring: Pingdom or StatusCake

**Security:**
- Supabase RLS for data isolation
- WAF (Web Application Firewall): Cloudflare
- DDoS protection: Cloudflare
- Penetration testing: Annual third-party audit

### Development Tools

**Code Quality:**
- ESLint + TypeScript ESLint
- Prettier for code formatting
- Husky for git hooks
- Commitlint for commit message standards

**Testing:**
- Vitest for unit testing
- React Testing Library for component testing
- Playwright for E2E testing
- Supabase local development for integration testing

**Documentation:**
- Storybook for component documentation
- OpenAPI/Swagger for API documentation
- Docusaurus for user documentation

---

## Success Metrics & KPIs

### Technical Metrics

- **System Uptime:** 99.9% availability
- **API Response Time:** <200ms for 95th percentile
- **Database Query Performance:** <50ms for 95% of queries
- **Vesting Job Reliability:** 100% daily execution success rate
- **Data Accuracy:** 0 discrepancies in share calculations

### Business Metrics

- **Companies Onboarded:** 50 companies in Year 1
- **Total Employees Managed:** 1,000,000+ by Year 2
- **User Adoption Rate:** 80% of employees log in within first month
- **Contract Signature Rate:** 95% within 7 days of issuance
- **Customer Retention:** 95% annual retention rate

### Compliance Metrics

- **Audit Trail Completeness:** 100% of transactions logged
- **Security Incidents:** 0 data breaches
- **Compliance Reports Generated:** 100% on-time submission
- **Failed Authentications:** <0.1% (detect account compromise)

---

## Risk Management

### Technical Risks

| Risk                          | Impact | Mitigation Strategy                          |
|-------------------------------|--------|----------------------------------------------|
| Vesting job failure           | High   | Redundant cron jobs, immediate alerting      |
| Data loss                     | High   | Daily backups, point-in-time recovery        |
| Performance degradation at scale | Medium | Load testing, query optimization, caching   |
| Third-party API downtime      | Medium | Caching, fallback providers, graceful degradation |

### Business Risks

| Risk                          | Impact | Mitigation Strategy                          |
|-------------------------------|--------|----------------------------------------------|
| Regulatory changes            | High   | Legal counsel on retainer, flexible architecture |
| Market adoption slowness      | Medium | Pilot program, free tier, extensive onboarding support |
| Competition from banks        | Medium | Differentiation via superior UX, faster time-to-market |
| Data breach                   | High   | Comprehensive security, insurance, incident response plan |

### Operational Risks

| Risk                          | Impact | Mitigation Strategy                          |
|-------------------------------|--------|----------------------------------------------|
| Key personnel departure       | Medium | Documentation, knowledge transfer, cross-training |
| Customer support overload     | Medium | Self-service knowledge base, chatbot, tiered support |
| Infrastructure cost overruns  | Low    | Cost monitoring, reserved instances, auto-scaling limits |

---

## Appendix: Glossary of Terms

- **CMA:** Capital Market Authority (Saudi Arabia's securities regulator)
- **ESOP:** Employee Stock Option Plan (right to purchase shares at a set price)
- **Grant:** Individual allocation of LTIP/ESOP shares to an employee
- **Grantee:** Employee receiving LTIP/ESOP shares
- **Issuer:** Company issuing LTIP/ESOP shares (publicly listed on Tadawul)
- **LTIP:** Long-Term Incentive Plan (direct share awards or restricted stock units)
- **Reserved Portfolio:** Company's internal safekeeping account for unvested shares
- **RLS:** Row-Level Security (database security mechanism)
- **RSA:** Restricted Stock Award (shares granted subject to vesting)
- **RSU:** Restricted Stock Unit (promise of shares subject to vesting)
- **Tadawul:** Saudi Stock Exchange
- **Vesting:** Process by which an employee earns the right to their granted shares
- **Vested Portfolio:** Employee's personal account holding fully vested shares

---

**End of Specification Document**

*This document is a living specification and will be updated as the platform evolves through development phases.*
