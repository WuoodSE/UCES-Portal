// ════════════════════════════════════════════════════════════
// UCES — University Course Evaluation System
// TypeScript Data Models
// Aligned with app.html prototype + SCHEMA.sql
// ════════════════════════════════════════════════════════════

// ─────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────

export type UserRole = "student" | "instructor" | "dept_head" | "admin";
export type CourseCategory = "Core" | "Elective" | "Foundation";

/** Likert scale rating: 1 (Poor) → 5 (Excellent) */
export type LikertScore = 1 | 2 | 3 | 4 | 5;

export const LIKERT_LABELS: Record<LikertScore, string> = {
  1: "Poor",
  2: "Fair",
  3: "Good",
  4: "Very Good",
  5: "Excellent",
};

// ─────────────────────────────────────────
// DEPARTMENT
// ─────────────────────────────────────────

export interface Department {
  id: string;          // UUID
  name: string;        // e.g. "Computer Science"
  code: string;        // e.g. "CS" — unique
  createdAt: Date;
}

// ─────────────────────────────────────────
// USER
// ─────────────────────────────────────────

export interface User {
  id: string;                // UUID
  fullName: string;
  email: string;             // university domain, unique
  role: UserRole;
  departmentId: string;      // FK → Department
  department?: Department;   // populated join
  studentYear?: number;      // 1–6, students only
  title?: string;            // e.g. "Associate Professor", admins/instructors
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

/** Subset returned by GET /auth/me — no sensitive fields */
export interface UserProfile {
  id: string;
  fullName: string;
  email: string;
  role: UserRole;
  department: string;        // department name
  studentYear?: number;
  title?: string;
}

// ─────────────────────────────────────────
// SEMESTER
// ─────────────────────────────────────────

export interface Semester {
  id: string;                // UUID
  label: string;             // e.g. "Fall 2024-2025"
  startDate: string;         // ISO date
  endDate: string;           // ISO date
  isCurrent: boolean;
  createdAt: Date;
}

// ─────────────────────────────────────────
// COURSE
// ─────────────────────────────────────────

export interface Course {
  id: string;                // UUID
  code: string;              // e.g. "CS301" — unique
  title: string;             // e.g. "Software Engineering"
  departmentId: string;      // FK → Department
  instructorId: string;      // FK → User (instructor)
  credits: number;           // 1–6
  category: CourseCategory;
  createdAt: Date;

  // Joined / computed fields (not stored)
  department?: Department;
  instructor?: UserProfile;
  windowOpen?: boolean;      // derived from active EvaluationWindow
}

// ─────────────────────────────────────────
// ENROLLMENT
// ─────────────────────────────────────────

export interface Enrollment {
  id: string;
  studentId: string;         // FK → User (student)
  courseId: string;          // FK → Course
  semesterId: string;        // FK → Semester
  enrolledAt: Date;

  // Joined
  course?: Course;
  semester?: Semester;
}

// ─────────────────────────────────────────
// EVALUATION WINDOW
// ─────────────────────────────────────────

export interface EvaluationWindow {
  id: string;
  courseId: string;          // FK → Course
  semesterId: string;        // FK → Semester
  opensAt: Date;
  closesAt: Date;
  isActive: boolean;
  createdBy: string;         // FK → User (admin)
  createdAt: Date;

  // Joined
  course?: Course;
  semester?: Semester;
}

// ─────────────────────────────────────────
// EVALUATION RESPONSE  (one per anonymous submission)
// ─────────────────────────────────────────

/**
 * Stored in evaluation_responses table.
 * anonymousToken = HMAC-SHA256(studentId + ":" + windowId, SERVER_SECRET)
 * — prevents double-submission without linking studentId to answers.
 */
export interface EvaluationResponse {
  id: string;
  windowId: string;          // FK → EvaluationWindow
  anonymousToken: string;    // 64-char hex HMAC — NOT reversible to studentId
  instructorScore: LikertScore;
  contentScore: LikertScore;
  assignmentsScore: LikertScore;
  resourcesScore: LikertScore;
  overallScore: LikertScore;
  commentText: string | null;
  submittedAt: Date;

  // Computed
  averageScore?: number;     // (sum of 5 scores) / 5
}

/** DTO used when a student submits a new evaluation (POST /windows/:id/submit) */
export interface SubmitEvaluationDto {
  instructorScore: LikertScore;
  contentScore: LikertScore;
  assignmentsScore: LikertScore;
  resourcesScore: LikertScore;
  overallScore: LikertScore;
  commentText?: string;
}

// ─────────────────────────────────────────
// ANALYTICS / DASHBOARD TYPES
// ─────────────────────────────────────────

/** Aggregated scores per course — returned by GET /results/courses/:id */
export interface CourseResultSummary {
  courseId: string;
  courseCode: string;
  courseTitle: string;
  semester: string;
  responseCount: number;
  participationRate: number; // 0–1
  avgInstructor: number;
  avgContent: number;
  avgAssignments: number;
  avgResources: number;
  avgOverall: number;
  avgTotal: number;          // mean of the five averages
  recentComments: string[];  // anonymised, last 10
}

/** System-wide statistics — returned by GET /results/dashboard */
export interface AdminDashboard {
  semester: string;
  totalCourses: number;
  openWindows: number;
  totalResponses: number;
  participationRate: number; // 0–100 percentage
  globalAvgScore: number;
  avgInstructor: number;
  avgContent: number;
  avgAssignments: number;
  avgResources: number;
  avgOverall: number;
  courseResults: CourseResultSummary[];
}

/** Used to indicate whether a student has already submitted for a given window */
export interface StudentWindowStatus {
  windowId: string;
  courseId: string;
  courseCode: string;
  courseTitle: string;
  isOpen: boolean;
  closesAt: Date;
  submitted: boolean;
}

// ─────────────────────────────────────────
// API RESPONSE WRAPPERS
// ─────────────────────────────────────────

export interface ApiSuccess<T> {
  status: "success";
  data: T;
}

export interface ApiError {
  status: "error";
  code: string;
  message: string;
}

export type ApiResponse<T> = ApiSuccess<T> | ApiError;

// ─────────────────────────────────────────
// AUTH TYPES
// ─────────────────────────────────────────

export interface LoginDto {
  email: string;
  password: string;
}

export interface LoginResponse {
  accessToken: string;       // JWT — expires in 8h
  user: UserProfile;
}
