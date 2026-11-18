# UCES — AI-Assisted Development Report

**Project:** University Course Evaluation System (UCES)  
**Semester:** Fall 2024–2025  
**Tool:** IBM Bob (AI-Assisted Software Development)  
**Report Type:** SDLC Process Documentation

---

## Part 1 — How IBM Bob Was Used in Each SDLC Phase

### Phase 1: Requirements Engineering

IBM Bob was used to analyse the project brief and produce a structured requirements document covering:

- **Stakeholder identification** — Bob enumerated all affected parties (students, instructors, department heads, administrators, IT staff, accreditation boards) and described each group's primary interests and system interactions.
- **Functional requirements** — Bob generated 17 functional requirements across five categories (authentication, student evaluation, evaluation management, results/reporting, system administration), directly traceable to the project description.
- **Non-functional requirements** — Bob identified eight measurable NFRs covering performance (2s dashboard load), security (bcrypt + JWT), anonymity (structural guarantee), availability (99.5% SLA), scalability, accessibility (WCAG 2.1 AA), maintainability, and data retention (5 years).
- **User stories** — Bob produced 10 role-attributed user stories in standard format, each with acceptance conditions aligned to the functional requirements.

**Time saved:** What would normally require two to three workshop sessions and a full day of documentation was completed in a single prompt-response cycle, with the human then reviewing and validating each item.

---

### Phase 2: System Design & Architecture

Bob proposed the complete three-tier system architecture:

- **Client layer:** React 18 SPA (Vite + TypeScript) communicating via HTTPS REST
- **Application layer:** Node.js / Express API behind Nginx reverse proxy with JWT middleware
- **Data layer:** PostgreSQL 15 (primary) + Redis (token blacklist + rate limiting)
- **Support services:** Nodemailer for email reminders, PDFKit for report export

Bob also designed the **anonymity mechanism** — a non-obvious security requirement. The proposed solution uses HMAC-SHA256 hashing of `(studentId + ":" + windowId + SERVER_SECRET)` to generate a deterministic token that:
1. Prevents double-submission (token uniqueness constraint)
2. Never stores studentId alongside answer records
3. Remains irreversible from the response table alone

This design pattern was verified by the human architect before being accepted.

---

### Phase 3: Database Design

Bob produced the full relational schema from the requirements, correctly:

- Normalised the design to 3NF (nine tables, no redundant data)
- Identified the need for a dedicated `evaluation_windows` table separate from semesters, enabling multi-window and multi-course flexibility
- Defined appropriate CHECK constraints on Likert scores (1–5), date ordering, and credit ranges
- Created database VIEWs for frequently-needed analytics queries (`vw_course_averages`, `vw_participation`)
- Added strategic indexes on foreign keys and high-query columns

The schema is fully consistent with the `models.ts` TypeScript interfaces and the `app.html` prototype data structure.

---

### Phase 4: API Design

Bob generated the complete REST API specification:

- 15 endpoints following REST conventions (resource-based URLs, correct HTTP verbs)
- Role-based access matrix (Student / Instructor / Dept. Head / Admin) applied per endpoint
- Full JSON request and response shapes consistent with the TypeScript data models
- Meaningful error codes (`ALREADY_SUBMITTED`, `WINDOW_CLOSED`, `NOT_ENROLLED`) aligned to real business rules
- Query parameter specifications for filtering, pagination, and export format

---

### Phase 5: Frontend Development (Prototype)

Bob built the complete interactive prototype (`app.html`) — a self-contained vanilla HTML/CSS/JavaScript SPA requiring no build tools. Features implemented:

| Component | IBM Bob Implementation |
|-----------|----------------------|
| Login screen | Role-tab selector, animated form, demo credential hint |
| Sidebar navigation | Role-aware nav links, pending evaluation badge counter |
| Student dashboard | Stat cards, pending list, recently submitted table |
| Course grid | Status badges (Open/Closed/Submitted), evaluate button logic |
| Evaluation form | 5-category Likert star widgets with hover + click interaction |
| Star rating component | `mouseenter`/`mouseleave`/`click` binding, descriptive labels |
| Success page | Score breakdown, average calculation, back navigation |
| Admin dashboard | Global stats, dimension progress bars, SVG score ring, course table |
| Admin course results | Per-course card with 5-dimension grid and comment display |
| Recent feedback page | Anonymised comment feed with course attribution |
| User management | Full user directory table |

---

### Phase 6: Documentation

Bob generated all project documentation files:

- `README.md` — Setup instructions, feature table, demo credentials, architecture summary
- `SCHEMA.sql` — Full PostgreSQL schema with comments, indexes, views, and sample data
- `models.ts` — TypeScript interfaces for all domain entities, DTOs, and API wrappers
- `api.md` — Complete REST API reference with request/response examples and error codes
- `report.md` — This document

---

## Part 2 — Human Decisions and Reviews Performed

IBM Bob accelerated every phase, but human judgment was essential at the following decision points:

### Decision 1: Anonymity Depth and Scope
**What Bob produced:** The HMAC token approach for anonymous submission tracking.  
**Human review required:** The engineer validated that the HMAC secret storage (environment variable), key rotation policy, and the deliberate absence of a student-to-token mapping table together satisfy the university's data protection obligations. Bob can propose the pattern; only the human can confirm it meets institutional and legal policy.

### Decision 2: Evaluation Dimension Selection
**What Bob initially proposed:** A flexible per-course custom question set.  
**Human correction:** The scope was narrowed to five fixed dimensions (Instructor, Content, Assignments, Resources, Overall) applicable to all courses. Reason: per-course customisation would create administrative overhead, inconsistent data, and make cross-course comparison unreliable — a usability and analytics tradeoff that requires contextual judgment about the university's operational capacity.

### Decision 3: Pre-seeded Evaluation Data in the Prototype
**What Bob produced:** A prototype with empty state.  
**Human decision:** Five realistic pre-seeded evaluations were added so the Admin Dashboard would show meaningful data immediately on first load, making the prototype suitable for demonstration without manual data entry. This is a product decision about demo-readiness that Bob did not originate.

### Decision 4: Evaluation Question Wording
**What Bob proposed:** Technically correct but generic question hints.  
**Human refinement:** Question hint text was reviewed and edited to ensure culturally appropriate, unbiased, and academically sound phrasing — for example, replacing "Rate how good the instructor is" with "Clarity, engagement, knowledge, availability for students." Bias in evaluation questions can unfairly disadvantage instructors and must be reviewed by a human subject-matter expert.

### Decision 5: Technology Stack Constraints
**What Bob recommended:** Sensible defaults (React, Node, PostgreSQL, Redis).  
**Human validation:** The stack was cross-checked against the university IT department's existing infrastructure, open-source licensing requirements, and the development team's skill set. Bob cannot know these institutional constraints.

### Decision 6: Data Retention Policy
**What Bob left open:** "Retain historical evaluation data."  
**Human decision:** Set to a minimum of 5 years, based on the university's academic records policy and accreditation requirements. This is a legal/compliance decision that cannot be inferred from system requirements alone.

### Decision 7: WCAG Compliance Level
**What Bob flagged:** "Accessibility compliance required."  
**Human decision:** WCAG 2.1 Level AA was selected based on the university's legal accessibility obligations. Bob identified the need; the human determined the required level.

### Decision 8: Window Closure Timing
**What Bob defaulted to:** Generic deadline warnings.  
**Human decision:** The 48-hour email reminder window and the December 20 deadline were chosen after considering the academic calendar, exam periods, and student availability — contextual knowledge that AI cannot independently determine.

---

## Part 3 — Responsible AI Considerations

### 3.1 Privacy by Design

The system is architecturally designed so that **no evaluation answer can ever be traced back to a specific student**. This is achieved through:

- The HMAC anonymous token — a one-way function that confirms a student has or hasn't submitted without storing their identity alongside answers
- No student ID field in the `evaluation_responses` table
- Comments displayed to instructors and admins without any attribution metadata
- The admin dashboard shows only aggregate statistics — individual responses are never surfaced by user

This is a **structural privacy guarantee**, not a policy promise. The architecture enforces it regardless of who has database access.

---

### 3.2 Fairness and Bias Prevention

**Question design bias:** Evaluation questions were reviewed to avoid leading language, cultural bias, or framing that could systematically disadvantage instructors based on teaching style, accent, or course difficulty rather than pedagogical quality.

**Statistical fairness:** All scores are presented with sample size context. A single low rating does not represent a course average. The system explicitly discourages using evaluation data as a sole input for personnel decisions.

**Score display with distribution:** The admin dashboard displays averages alongside response counts, preventing misinterpretation of small-sample averages as representative results.

---

### 3.3 Transparency

**Student-facing:** Before submitting, students see an anonymity notice explaining exactly how their data is used, how long it is retained, and who can access results. This is displayed as a visible UI element — not buried in terms of service.

**Instructor-facing:** Instructors are informed that they will see aggregated scores and anonymised comments — not individual responses or student identities.

**Audit trail:** All administrative actions (opening/closing evaluation windows, editing question templates, accessing exports) are logged in an audit table with timestamps and actor IDs.

---

### 3.4 Accountability

- All mutations to sensitive data require authenticated admin tokens
- Evaluation data is scoped exclusively to **academic quality improvement** — the system does not support punitive use
- Decision-making authority remains with the department head and HR processes — the system provides data to **support** human decisions, not replace them
- IBM Bob was used as a productivity tool; every design decision, schema choice, and feature was reviewed and approved by human participants before being accepted

---

### 3.5 Non-Maleficence

- Open-text comments are not indexed for full-text search to prevent attempts to identify students through writing style
- No student can see another student's evaluation status or submission
- The system has no mechanism to correlate a student's grade with their evaluation submission
- Rate limiting is enforced on the submission endpoint to prevent automated abuse

---

### 3.6 Inclusivity and Accessibility

- **Mobile-responsive** layout — students without desktop access can participate equally
- **WCAG 2.1 AA** compliance target — keyboard navigation and screen reader support throughout
- **Star rating accessibility** — each star widget is operable via keyboard and reports descriptive state to assistive technologies
- **Language:** All UI text is written in plain, clear English appropriate for a university audience regardless of technical background

---

### 3.7 AI as Amplifier, Not Replacement

The most important Responsible AI principle applied in this project is that **IBM Bob was treated as a productivity amplifier, not an autonomous decision-maker**.

Every output Bob generated was:
1. Reviewed by a human before being accepted
2. Validated against institutional constraints Bob cannot know
3. Adjusted where the AI-generated content was technically correct but contextually inappropriate
4. Documented with the human review decisions recorded in this report

The engineering judgment, privacy decisions, legal compliance choices, and final architectural approvals all remained with the human team. Bob reduced the time required to produce high-quality outputs — it did not remove the need for qualified human oversight.

---

*Report prepared with IBM Bob — University Course Evaluation System, Fall 2024–2025*
