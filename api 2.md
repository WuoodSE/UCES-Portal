# UCES REST API Documentation

> **Base URL:** `https://api.uces.university.edu/v1`  
> **Authentication:** `Authorization: Bearer <jwt_token>` on all protected endpoints  
> **Content-Type:** `application/json`  
> **Semester context:** Automatically resolved from the current active semester unless specified

---

## Authentication

### POST /auth/login
Authenticate a user and receive a JWT access token.

**Access:** Public

**Request Body:**
```json
{
  "email": "ahmad@university.edu",
  "password": "securepassword"
}
```

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9…",
    "user": {
      "id": "uuid-s001",
      "fullName": "Ahmad Al-Zahrawi",
      "email": "ahmad@university.edu",
      "role": "student",
      "department": "Computer Science",
      "studentYear": 3
    }
  }
}
```

**Response 401:**
```json
{ "status": "error", "code": "INVALID_CREDENTIALS", "message": "Email or password is incorrect." }
```

---

### POST /auth/logout
Invalidate the current JWT (added to Redis blacklist).

**Access:** Authenticated

**Response 200:**
```json
{ "status": "success", "data": { "message": "Logged out successfully." } }
```

---

### GET /auth/me
Return the current authenticated user's profile.

**Access:** Authenticated

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "id": "uuid-s001",
    "fullName": "Ahmad Al-Zahrawi",
    "email": "ahmad@university.edu",
    "role": "student",
    "department": "Computer Science",
    "studentYear": 3
  }
}
```

---

## Courses

### GET /courses
List courses. Scope depends on role:
- **Student:** enrolled courses for the current semester
- **Instructor:** courses they teach
- **Admin / Dept. Head:** all courses (filterable)

**Access:** Authenticated

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `semesterId` | UUID | Filter by semester (defaults to current) |
| `departmentId` | UUID | Filter by department (admin only) |
| `windowOpen` | boolean | Filter by evaluation window status |

**Response 200:**
```json
{
  "status": "success",
  "data": [
    {
      "id": "uuid-c001",
      "code": "CS301",
      "title": "Software Engineering",
      "instructor": { "id": "uuid-u004", "fullName": "Dr. Khalid Nasser" },
      "department": "Computer Science",
      "credits": 3,
      "category": "Core",
      "windowOpen": true,
      "closesAt": "2024-12-20T23:59:00Z"
    }
  ]
}
```

---

### GET /courses/:id
Get detailed information about a single course.

**Access:** Authenticated

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "id": "uuid-c001",
    "code": "CS301",
    "title": "Software Engineering",
    "instructor": { "id": "uuid-u004", "fullName": "Dr. Khalid Nasser", "title": "Associate Professor" },
    "department": "Computer Science",
    "credits": 3,
    "category": "Core",
    "windowOpen": true,
    "opensAt": "2024-12-01T00:00:00Z",
    "closesAt": "2024-12-20T23:59:00Z"
  }
}
```

---

### POST /courses
Create a new course.

**Access:** Admin only

**Request Body:**
```json
{
  "code": "CS410",
  "title": "Advanced Software Architecture",
  "departmentId": "uuid-dept-cs",
  "instructorId": "uuid-u004",
  "credits": 3,
  "category": "Elective"
}
```

**Response 201:**
```json
{
  "status": "success",
  "data": { "id": "uuid-new", "code": "CS410", "title": "Advanced Software Architecture" }
}
```

---

### PUT /courses/:id
Update course details.

**Access:** Admin only

**Request Body:** (partial update — send only fields to change)
```json
{ "title": "Advanced Software Architecture & Design", "credits": 4 }
```

**Response 200:**
```json
{ "status": "success", "data": { "id": "uuid-c010", "title": "Advanced Software Architecture & Design" } }
```

---

## Evaluation Windows

### GET /windows
List evaluation windows.

**Access:** Authenticated

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `active` | boolean | If `true`, return only currently open windows |
| `semesterId` | UUID | Filter by semester |
| `courseId` | UUID | Filter by course |

**Response 200:**
```json
{
  "status": "success",
  "data": [
    {
      "id": "uuid-w001",
      "courseId": "uuid-c001",
      "courseCode": "CS301",
      "courseTitle": "Software Engineering",
      "semesterId": "uuid-sem001",
      "semester": "Fall 2024-2025",
      "opensAt": "2024-12-01T00:00:00Z",
      "closesAt": "2024-12-20T23:59:00Z",
      "isActive": true
    }
  ]
}
```

---

### POST /windows
Create a new evaluation window.

**Access:** Admin only

**Request Body:**
```json
{
  "courseId": "uuid-c001",
  "semesterId": "uuid-sem001",
  "opensAt": "2024-12-01T00:00:00Z",
  "closesAt": "2024-12-20T23:59:00Z"
}
```

**Response 201:**
```json
{
  "status": "success",
  "data": { "id": "uuid-w001", "isActive": true, "opensAt": "2024-12-01T00:00:00Z" }
}
```

---

### PUT /windows/:id/close
Close an evaluation window early.

**Access:** Admin only

**Response 200:**
```json
{ "status": "success", "data": { "id": "uuid-w001", "isActive": false, "closedAt": "2024-12-15T12:00:00Z" } }
```

---

## Evaluations (Student Submission)

### GET /enrollments/me/pending
Return all courses the current student is enrolled in that have an open evaluation window they have **not yet** submitted.

**Access:** Student

**Response 200:**
```json
{
  "status": "success",
  "data": [
    {
      "windowId": "uuid-w001",
      "courseId": "uuid-c001",
      "courseCode": "CS301",
      "courseTitle": "Software Engineering",
      "instructor": "Dr. Khalid Nasser",
      "isOpen": true,
      "closesAt": "2024-12-20T23:59:00Z",
      "submitted": false
    }
  ]
}
```

---

### POST /windows/:id/submit
Submit an anonymous evaluation for an open window.

**Access:** Student (must be enrolled in the course; one submission per window)

**Request Body:**
```json
{
  "instructorScore": 5,
  "contentScore": 4,
  "assignmentsScore": 4,
  "resourcesScore": 5,
  "overallScore": 5,
  "commentText": "Dr. Nasser is exceptional. Clear explanations and always available for questions."
}
```

**Response 201:**
```json
{
  "status": "success",
  "data": {
    "message": "Evaluation submitted successfully.",
    "submittedAt": "2024-12-10T09:14:00Z",
    "averageScore": 4.6
  }
}
```

**Response 409 (already submitted):**
```json
{ "status": "error", "code": "ALREADY_SUBMITTED", "message": "You have already submitted an evaluation for this course." }
```

**Response 403 (window closed):**
```json
{ "status": "error", "code": "WINDOW_CLOSED", "message": "The evaluation window for this course is no longer open." }
```

---

## Results & Analytics

### GET /results/courses/:id
Aggregated evaluation results for a specific course.

**Access:** Instructor (own courses), Dept. Head (department courses), Admin (all)

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `semesterId` | UUID | Defaults to current semester |

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "courseId": "uuid-c001",
    "courseCode": "CS301",
    "courseTitle": "Software Engineering",
    "semester": "Fall 2024-2025",
    "responseCount": 42,
    "participationRate": 0.84,
    "avgInstructor": 4.7,
    "avgContent": 4.3,
    "avgAssignments": 4.1,
    "avgResources": 4.5,
    "avgOverall": 4.6,
    "avgTotal": 4.44,
    "recentComments": [
      "Dr. Nasser is exceptional. Clear explanations and always available for questions.",
      "Great course structure. Would benefit from more practical case studies."
    ]
  }
}
```

---

### GET /results/departments/:id
Department-level summary of all course averages.

**Access:** Dept. Head (own department), Admin (all departments)

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "departmentId": "uuid-dept-cs",
    "department": "Computer Science",
    "semester": "Fall 2024-2025",
    "courseCount": 5,
    "totalResponses": 187,
    "departmentAvg": 4.21,
    "courses": [
      { "courseCode": "AI350", "title": "Introduction to AI & ML", "avgTotal": 4.80, "responses": 38 },
      { "courseCode": "CS301", "title": "Software Engineering",     "avgTotal": 4.44, "responses": 42 },
      { "courseCode": "CS240", "title": "Data Structures",          "avgTotal": 4.00, "responses": 40 },
      { "courseCode": "DB250", "title": "Database Management",      "avgTotal": 3.60, "responses": 35 },
      { "courseCode": "NET180","title": "Computer Networks",        "avgTotal": 4.20, "responses": 32 }
    ]
  }
}
```

---

### GET /results/dashboard
System-wide analytics dashboard for administrators.

**Access:** Admin only

**Response 200:**
```json
{
  "status": "success",
  "data": {
    "semester": "Fall 2024-2025",
    "totalCourses": 6,
    "openWindows": 5,
    "totalResponses": 5,
    "participationRate": 83.3,
    "globalAvgScore": 4.20,
    "avgInstructor": 4.20,
    "avgContent": 4.40,
    "avgAssignments": 4.00,
    "avgResources": 4.20,
    "avgOverall": 4.20,
    "courseResults": [ "…array of CourseResultSummary…" ]
  }
}
```

---

### GET /results/export
Export evaluation results as CSV or PDF.

**Access:** Dept. Head, Admin

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `format` | `csv` \| `pdf` | Output format (required) |
| `scope` | `department` \| `system` | Export scope |
| `semesterId` | UUID | Target semester (defaults to current) |
| `departmentId` | UUID | Required if scope=department |

**Response 200:** Binary stream with `Content-Disposition: attachment` header.

---

## Error Codes Reference

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INVALID_CREDENTIALS` | 401 | Wrong email or password |
| `UNAUTHORIZED` | 401 | Missing or expired JWT |
| `FORBIDDEN` | 403 | Role does not have permission |
| `WINDOW_CLOSED` | 403 | Evaluation window is not active |
| `NOT_ENROLLED` | 403 | Student not enrolled in this course |
| `ALREADY_SUBMITTED` | 409 | Duplicate submission attempt |
| `NOT_FOUND` | 404 | Resource does not exist |
| `VALIDATION_ERROR` | 422 | Request body failed validation |
| `RATE_LIMITED` | 429 | Too many requests |
| `SERVER_ERROR` | 500 | Unexpected server error |

---

## Role → Endpoint Access Matrix

| Endpoint | Student | Instructor | Dept. Head | Admin |
|----------|:-------:|:----------:|:----------:|:-----:|
| POST /auth/login | ✓ | ✓ | ✓ | ✓ |
| GET /courses | ✓ (enrolled) | ✓ (own) | ✓ | ✓ |
| GET /enrollments/me/pending | ✓ | — | — | — |
| POST /windows/:id/submit | ✓ | — | — | — |
| GET /results/courses/:id | — | ✓ (own) | ✓ | ✓ |
| GET /results/departments/:id | — | — | ✓ (own) | ✓ |
| GET /results/dashboard | — | — | — | ✓ |
| POST /windows | — | — | — | ✓ |
| PUT /windows/:id/close | — | — | — | ✓ |
| POST /courses | — | — | — | ✓ |
| GET /results/export | — | — | ✓ | ✓ |
