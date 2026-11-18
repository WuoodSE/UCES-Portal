# UCES — University Course Evaluation System

> A fully interactive, single-page web application that enables students to evaluate university courses and provides administrators with real-time analytics.

---

## Live Prototype

Open `app.html` directly in any modern browser. No build step, no server, no dependencies.

```
uces/
├── app.html      ← Complete interactive prototype (self-contained)
├── README.md     ← This file
├── SCHEMA.sql    ← PostgreSQL database schema
├── models.ts     ← TypeScript data models
├── api.md        ← REST API documentation
└── report.md     ← IBM Bob usage, human review & Responsible AI report
```

---

## Features

### Student Portal
| Feature | Description |
|---------|-------------|
| **Login** | Role-based login (Student / Administrator) |
| **Dashboard** | Progress overview, pending evaluations, recently submitted |
| **My Courses** | All 6 enrolled courses with status badges (Open / Closed / Submitted) |
| **Evaluate** | Interactive 5-star rating form — Instructor, Content, Assignments, Resources, Overall |
| **Comments** | Optional free-text feedback per evaluation |
| **Success Page** | Confirmation with score breakdown after submission |
| **My Evaluations** | Full history table of all submitted evaluations |

### Admin Portal
| Feature | Description |
|---------|-------------|
| **Dashboard** | Global avg score, participation rate, dimension breakdown bars, score ring |
| **Course Results** | Per-course detailed breakdown with star ratings and comments |
| **Recent Feedback** | Anonymised comment feed across all courses |
| **User Management** | Directory of all registered users and roles |

---

## Sample Data (Built-in)

### Users
| ID | Name | Role |
|----|------|------|
| S001 | Ahmad Al-Zahrawi | Student — Computer Science, 3rd Year |
| A001 | Dr. Nadia Al-Farsi | Administrator — Academic Affairs Director |

### Courses (Fall 2024–2025)
| Code | Title | Instructor | Window |
|------|-------|------------|--------|
| CS301 | Software Engineering | Dr. Khalid Nasser | Open |
| CS240 | Data Structures & Algorithms | Dr. Sara Al-Mansouri | Open |
| DB250 | Database Management Systems | Dr. Layla Hamdan | Open |
| NET180 | Computer Networks | Dr. Omar Bishara | Open |
| AI350 | Introduction to AI & ML | Dr. Fatima Al-Sayed | Open |
| MATH201 | Discrete Mathematics | Dr. Reem Qasim | **Closed** |

### Evaluation Dimensions (Likert 1–5)
1. Instructor Rating
2. Course Content
3. Assignments & Exams
4. Learning Resources
5. Overall Satisfaction

---

## How to Run

```bash
# Option 1 — Double-click
# Simply open uces/app.html in Chrome, Edge, Firefox, or Safari.

# Option 2 — Local server (optional)
npx serve uces
# Then visit http://localhost:3000
```

### Demo Credentials
| Role | Email | Password |
|------|-------|----------|
| Student | ahmad@university.edu | (any) |
| Admin | nadia@university.edu | (any) |

Select the role tab on the login screen and click **Sign In**.

---

## Architecture

This prototype is built as a **vanilla HTML/CSS/JavaScript SPA** — a single file with no external dependencies. In a production deployment it would be replaced by:

| Layer | Production Stack |
|-------|-----------------|
| Frontend | React 18 + TypeScript + Vite |
| UI Components | shadcn/ui + Tailwind CSS |
| State | Zustand |
| Backend | Node.js + Express + TypeScript |
| ORM | Prisma |
| Database | PostgreSQL 15 |
| Cache | Redis |
| Auth | JWT (httpOnly cookies) |
| Hosting | Docker + Nginx + GitHub Actions CI/CD |

See `SCHEMA.sql`, `models.ts`, and `api.md` for the full production-ready specification.

---

## Evaluation Questions
All five questions use a 1–5 Likert scale with hover interaction and descriptive labels:

| Score | Label |
|-------|-------|
| 1 | Poor |
| 2 | Fair |
| 3 | Good |
| 4 | Very Good |
| 5 | Excellent |

---

## Anonymity Design

Each submission is stored without any link to the submitting student's identity. In the production backend:

```
anonymous_token = HMAC-SHA256(studentId + ":" + windowId, SERVER_SECRET)
```

The token prevents double-submission without storing the student–response mapping.

---

## Project Information

| Field | Value |
|-------|-------|
| Project Name | University Course Evaluation System (UCES) |
| Semester | Fall 2024–2025 |
| Development Method | AI-Assisted SDLC with IBM Bob |
| Prototype Type | Self-contained interactive HTML SPA |
| Compliance | WCAG 2.1 AA (keyboard navigable, screen-reader compatible) |

---

*Built with IBM Bob — AI-Assisted Software Development*
