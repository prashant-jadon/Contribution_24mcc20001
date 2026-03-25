# 🏗️ System Architecture - Future Titans Platform

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      FRONTEND (Next.js 14)                      │
│                    (React + Tailwind + ShadCN)                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │ Landing  │  │  Student │  │  Admin   │  │  Auth    │       │
│  │  Page    │  │  Portal  │  │  Portal  │  │  Pages   │       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
│       │              │             │            │               │
│       └──────────────┴─────────────┴────────────┘               │
│                      │                                           │
│              ┌───────▼────────┐                                 │
│              │   HTTP Client  │  (Axios)                       │
│              │  with JWT Auth │                                 │
│              └───────┬────────┘                                 │
│                      │                                           │
│         ┌────────────┴────────────┐                             │
│         │    Zustand Store        │                             │
│         │  (Auth + UI State)      │                             │
│         └────────────┬────────────┘                             │
└─────────────────────┼──────────────────────────────────────────┘
                      │ API Requests (HTTPS)
                      │
┌─────────────────────▼──────────────────────────────────────────┐
│                  BACKEND (Express.js)                           │
│                   Running on Port 5006                          │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐   │
│  │              Route Handlers (Express)                  │   │
│  │  ┌─────────┐ ┌────────┐ ┌────────┐ ┌──────────────┐  │   │
│  │  │  Auth   │ │Payment │ │Modules │ │Submissions   │  │   │
│  │  │ Routes  │ │Routes  │ │Routes  │ │Routes        │  │   │
│  │  └────┬────┘ └───┬────┘ └───┬────┘ └──────┬───────┘  │   │
│  │       │          │          │            │           │   │
│  │  ┌────▼──────────▼──────────▼────────────▼────┐     │   │
│  │  │    Middleware Layer                         │     │   │
│  │  │  - Authentication (JWT)                     │     │   │
│  │  │  - Rate Limiting                            │     │   │
│  │  │  - Error Handling                           │     │   │
│  │  │  - File Upload (Multer)                     │     │   │
│  │  │  - CORS & Security (Helmet)                 │     │   │
│  │  └────┬─────────────────────────────────────────┘     │   │
│  └───────┼──────────────────────────────────────────────┘   │
│          │                                                    │
│  ┌───────▼──────────────────────────────────────────────┐   │
│  │          Service Layer                               │   │
│  │  ┌──────────────┐         ┌────────────────────┐    │   │
│  │  │  AI Engine   │         │ Payment Service    │    │   │
│  │  │ (Gemini API) │         │(Razorpay)          │    │   │
│  │  │              │         │                    │    │   │
│  │  │ - Context    │         │- Order Creation    │    │   │
│  │  │   Injection  │         │- Verification      │    │   │
│  │  │ - SURGE      │         │- Refunds           │    │   │
│  │  │   Scoring    │         │                    │    │   │
│  │  │ - SSI Calc   │         │                    │    │   │
│  │  └──────────────┘         └────────────────────┘    │   │
│  └─────────────────────┬──────────────────────────────┘   │
│                        │                                    │
│  ┌─────────────────────▼──────────────────────────────┐   │
│  │         Data Access Layer (Mongoose)              │   │
│  │  ┌──────┐ ┌────────┐ ┌─────────┐ ┌──────────┐   │   │
│  │  │User  │ │Module  │ │AIChat   │ │Submission│  │   │
│  │  │Model │ │Model   │ │Model    │ │Model     │  │   │
│  │  └──────┘ └────────┘ └─────────┘ └──────────┘   │   │
│  └─────────────────────┬──────────────────────────────┘   │
│                        │                                    │
└────────────────────────┼────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
┌───────▼────────┐  ┌───▼─────┐   ┌───────▼──────┐
│   MongoDB      │  │Razorpay │   │Google Gemini │
│   Database     │  │ API     │   │  API         │
└────────────────┘  └─────────┘   └──────────────┘
```

## Component Architecture (Frontend)

### Page Structure (App Router)

```
app/
├── page.js                          # Landing page
├── layout.js                        # Root layout
├── globals.css                      # Global styles
├── (auth)/
│   ├── signup/page.js              # Student signup
│   └── login/page.js               # Student/Admin login
├── (student)/
│   ├── layout.js                   # Student layout with navbar
│   ├── dashboard/page.js           # Progress dashboard
│   ├── modules/page.js             # Module listing
│   ├── modules/[moduleId]/page.js  # Module detail
│   ├── modules/[moduleId]/[chapterId]/page.js  # Chapter player
│   ├── chat/[moduleId]/[chapterId]/page.js     # AI chat
│   ├── submission/page.js          # Idea submission form
│   └── payment/page.js             # Payment checkout
└── admin/
    ├── layout.js                   # Admin layout with sidebar
    ├── page.js                     # Admin dashboard
    ├── students/page.js            # Student management
    ├── students/[studentId]/page.js # Student detail
    ├── modules/page.js             # Module management
    ├── modules/[moduleId]/edit/page.js # Module editor
    ├── submissions/page.js         # Submission reviewer
    └── analytics/page.js           # Analytics dashboard
```

### Component Organization

```
components/
├── shared/                         # Shared across app
│   ├── Navbar.js                  # Top navigation
│   ├── Sidebar.js                 # Admin sidebar
│   ├── Header.js                  # Page header
│   ├── LoadingSpinner.js          # Loading indicator
│   ├── ErrorBoundary.js           # Error handling
│   └── Footer.js                  # Page footer
├── student/                        # Student-specific
│   ├── ModuleCard.js              # Module preview card
│   ├── ChapterPlayer.js           # Chapter content player
│   ├── AIChat.js                  # AI co-founder chat
│   ├── SubmissionForm.js          # Idea form component
│   └── SSIScoreCard.js            # SSI score display
├── admin/                          # Admin-specific
│   ├── Dashboard.js               # Admin dashboard
│   ├── StudentList.js             # Student table
│   ├── ModuleBuilder.js           # Module creator
│   ├── SubmissionViewer.js        # Submission reviewer
│   ├── Analytics.js               # Analytics charts
│   └── ChapterEditor.js           # Chapter editor
└── forms/                          # Form components
    ├── IdeaSubmissionForm.js      # Long submission form
    ├── LoginForm.js               # Login form
    ├── SignupForm.js              # Signup form
    └── PaymentForm.js             # Payment form
```

## Data Flow Architecture

### Student Learning Flow

```
1. AUTHENTICATION
   ├─ User clicks "Sign Up"
   ├─ Fills registration form
   ├─ POST /api/auth/signup
   ├─ Backend: Hash password, create User doc
   ├─ Backend: Generate JWT + Refresh token
   └─ Frontend: Store tokens, redirect to dashboard

2. PAYMENT
   ├─ User clicks "Complete Payment"
   ├─ POST /api/payment/initiate
   ├─ Backend: Create Razorpay order
   ├─ Frontend: Open Razorpay modal
   ├─ User: Enter card details
   ├─ Razorpay: Sends webhook
   ├─ Backend: Verify signature, update User.isPaid = true
   └─ Frontend: Redirect to modules

3. MODULE LEARNING
   ├─ User: Selects module
   ├─ GET /api/modules/:id
   ├─ Backend: Returns module + chapters
   ├─ Frontend: Display chapter list
   ├─ User: Clicks chapter
   ├─ GET /api/modules/:moduleId/chapters/:chapterId
   └─ Frontend: Display content + AI Chat button

4. AI INTERACTION
   ├─ User: Types message in AI chat
   ├─ Frontend: Saves to local state
   ├─ POST /api/chat/:moduleId/chapters/:chapterId/message
   ├─ Backend: AI Engine processes message
   │  ├─ Load chapter context (subtitles, content)
   │  ├─ Load student profile + history
   │  ├─ Call Gemini API
   │  ├─ Analyze response quality
   │  ├─ Calculate SSI scores (SURGE dimensions)
   │  └─ Save AIChat document
   ├─ Backend: Returns AI response + SSI scores
   ├─ Frontend: Display AI message + update SSI display
   └─ User: Continue conversation or move to next chapter

5. CHAPTER COMPLETION
   ├─ User: Finishes AI conversation
   ├─ POST /api/chat/:moduleId/chapters/:chapterId/complete
   ├─ Backend: Mark chapter as completed
   ├─ Backend: Update User.modulesProgress
   ├─ Backend: Aggregate SSI scores
   ├─ Frontend: Show progress animation
   └─ Frontend: Unlock next chapter or final submission

6. IDEA SUBMISSION
   ├─ User: All modules completed
   ├─ Clicks "Submit Idea"
   ├─ Frontend: Display submission form
   ├─ User: Fills all form fields
   ├─ User: Uploads PDF + Video
   ├─ POST /api/submission/submit (multipart/form-data)
   ├─ Backend: Validate files, store in /uploads
   ├─ Backend: Create IdeaSubmission document
   ├─ Backend: Update User.ideaSubmission
   └─ Frontend: Show success confirmation
```

### Admin Management Flow

```
1. ADMIN LOGIN
   ├─ Admin: Email + Password
   ├─ POST /api/auth/login
   ├─ Backend: Verify, check role === 'admin'
   ├─ Backend: Generate JWT (claims role: 'admin')
   └─ Frontend: Redirect to /admin dashboard

2. STUDENT MANAGEMENT
   ├─ Admin: Navigates to "Students"
   ├─ GET /api/admin/students?filters
   ├─ Backend: Query User collection with filters
   ├─ Frontend: Display table with pagination
   ├─ Admin: Clicks student row
   ├─ GET /api/admin/students/:studentId
   ├─ Backend: Return student detail + AI chats + submission
   └─ Frontend: Display student profile

3. MODULE MANAGEMENT
   ├─ Admin: Clicks "Create Module"
   ├─ POST /api/modules (with auth: admin)
   ├─ Backend: Create Module document
   ├─ Admin: Adds chapters
   ├─ POST /api/modules/:moduleId/chapters
   ├─ Backend: Create Chapter, add to Module.chapters
   ├─ Admin: Uploads content
   ├─ Frontend: File upload to /uploads
   ├─ Admin: Clicks "Publish"
   ├─ POST /api/modules/:moduleId/publish
   └─ Backend: Set isPublished = true

4. SUBMISSION REVIEW
   ├─ Admin: Views "Submissions"
   ├─ GET /api/submission/admin/all
   ├─ Backend: Return all IdeaSubmission docs
   ├─ Frontend: Show submission list
   ├─ Admin: Clicks submission
   ├─ GET /api/submission/admin/:submissionId
   ├─ Backend: Return full submission + student data
   ├─ Frontend: Display PDF inline + video player
   ├─ Admin: Enters score + comments
   ├─ PUT /api/submission/admin/:submissionId/score
   └─ Backend: Update adminScore, adminNotes, status
```

## API Request/Response Pattern

### Authentication Flow
```javascript
// Request
POST /api/auth/login
{
  email: "user@example.com",
  password: "hashedPassword"
}

// Response (200)
{
  message: "Login successful",
  accessToken: "eyJhbGc...",
  refreshToken: "eyJhbGc...",
  user: {
    id: "ObjectId",
    name: "John Doe",
    email: "user@example.com",
    role: "student",
    isPaid: false
  }
}

// Error Response (401)
{
  error: "Invalid credentials"
}
```

### AI Chat Request/Response
```javascript
// Request
POST /api/chat/moduleId/chapters/chapterId/message
Header: Authorization: Bearer accessToken
{
  message: "What is entrepreneurship?"
}

// Response (200)
{
  aiMessage: "Entrepreneurship is the process of creating...",
  ssiScore: {
    overall: 72,
    selfAwareness: 80,
    understandingOpportunities: 70,
    resilience: 65,
    growthExecution: 75,
    entrepreneurialLeadership: 68
  },
  interactionMetrics: {
    creativeScore: 75,
    clarityScore: 80,
    resilienceIndicators: 60,
    decisionMakingQuality: 70,
    communicationQuality: 78
  },
  conversationLength: 5
}
```

## Database Relationships

```
User (1) ──────────────────────┐
  │                            │
  ├─ modulesProgress (array)   │
  │   └─ moduleId ──> Module   │
  │   └─ completedChapters []─┐│
  │                           ││
  ├─ ideaSubmission ────────┐ ││
  │                         │ ││
  ├─ razorpayPaymentId     │ ││
  │                        │ ││
  └─ ssiBreakdown         │ ││
                          │ ││
Module (1) ─┬────────────┘ ││
     │      │              ││
     │      └──────────────┘│
     ├─ chapters []        │
     │    └─ Chapter[]    │
     │        └─> AIChat[]│
     │            └─> User
     └─ createdBy ──> User
                        │
Chapter (1) ────────────┤
     │                  │
     ├─ moduleId ──────┤
     └─ aiChatSession  │
        └─> AIChat[]   │
            └─> User ──┤
                       │
AIChat (1) ────────────┤
     ├─ studentId ─────┤
     ├─ chapterId
     ├─ moduleId
     └─ ssiScore

IdeaSubmission (1) ────┴─> User
     ├─ studentId ────────┘
     ├─ teamMembers []
     ├─ projectTitle
     └─ submissionStatus
```

## Security Architecture

```
┌──────────────────────────────────────────────────────┐
│             SECURITY LAYERS                          │
├──────────────────────────────────────────────────────┤
│ 1. TRANSPORT SECURITY                                │
│    ├─ HTTPS/TLS encryption                           │
│    ├─ CORS validation                                │
│    └─ Helmet security headers                        │
├──────────────────────────────────────────────────────┤
│ 2. AUTHENTICATION                                    │
│    ├─ JWT tokens (short-lived: 15min)               │
│    ├─ Refresh tokens (long-lived: 7d)               │
│    ├─ Bcrypt password hashing (10 rounds)            │
│    └─ Token stored in HTTP-only cookies              │
├──────────────────────────────────────────────────────┤
│ 3. AUTHORIZATION                                     │
│    ├─ Role-based access control (RBAC)              │
│    ├─ Token verified on every request                │
│    ├─ Resource ownership validation                  │
│    └─ Admin-only endpoint protection                 │
├──────────────────────────────────────────────────────┤
│ 4. INPUT VALIDATION                                  │
│    ├─ Joi schema validation                          │
│    ├─ MongoDB injection prevention                   │
│    ├─ File upload validation                         │
│    └─ Rate limiting per IP                           │
├──────────────────────────────────────────────────────┤
│ 5. DATA PROTECTION                                   │
│    ├─ Password hashing                               │
│    ├─ Sensitive data encrypted                       │
│    ├─ Database backups                               │
│    └─ GDPR compliance                                │
└──────────────────────────────────────────────────────┘
```

## Scalability Strategy

```
                           ┌─────────────────┐
                           │ Vercel CDN      │
                           │ (Static Assets) │
                           └────────┬────────┘
                                    │
          ┌─────────────────────────┼─────────────────────────┐
          │                         │                         │
    ┌─────▼────┐           ┌───────▼──────┐          ┌─────────▼──────┐
    │Frontend   │           │Load Balancer │          │Nginx Cache     │
    │Instances  │           │(Kubernetes)  │          │Layer           │
    │(N)        │           └───────┬──────┘          └────────┬───────┘
    └──────────┘                    │                        │
                                    │
                    ┌───────────────┼────────────────┐
                    │               │                │
              ┌─────▼────┐   ┌─────▼────┐    ┌─────▼────┐
              │Backend 1 │   │Backend 2 │    │Backend N │
              │(API)     │   │(API)     │    │(API)     │
              └────┬─────┘   └────┬─────┘    └────┬─────┘
                   │             │              │
                   └─────────────┼──────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                        │
            ┌──────▼────┐          ┌────────▼──────┐
            │MongoDB    │          │Redis Cluster  │
            │Replica Set│          │(Sessions/Cache)
            │(Sharded)  │          └───────────────┘
            └───────────┘
                 │
        ┌────────┴────────┐
        │                 │
   ┌────▼────┐      ┌────▼────┐
   │Backups  │      │Archives  │
   │(S3)     │      │(Glacier) │
   └─────────┘      └──────────┘
```

## Performance Optimization

1. **Frontend**
   - Code splitting with Next.js dynamic imports
   - Image optimization with Next.js Image component
   - Tailwind CSS purging for smaller bundle
   - Caching with SWR/React Query
   - Lazy loading components

2. **Backend**
   - Database indexing on frequently queried fields
   - Redis caching for module/user data
   - Connection pooling for DB
   - Async job processing with Bull Queue
   - CDN for file uploads (S3)

3. **Network**
   - HTTP/2 server push
   - Gzip compression
   - CloudFlare CDN
   - Geographic routing

## Monitoring & Observability

```
┌─────────────────────────────────────────┐
│        Monitoring Stack                  │
├─────────────────────────────────────────┤
│                                          │
│  Frontend:                               │
│  ├─ Sentry (Error tracking)              │
│  ├─ LogRocket (Session replay)           │
│  └─ Google Analytics                     │
│                                          │
│  Backend:                                │
│  ├─ DataDog (APM)                        │
│  ├─ Prometheus (Metrics)                 │
│  ├─ ELK Stack (Logs)                     │
│  └─ PagerDuty (Alerting)                 │
│                                          │
│  Database:                               │
│  ├─ MongoDB Ops Manager                  │
│  └─ Custom metrics (slow queries)        │
└─────────────────────────────────────────┘
```

---

This architecture is designed for:
- ✅ 10,000+ concurrent users
- ✅ Sub-100ms API response times
- ✅ 99.9% uptime
- ✅ Horizontal scaling
- ✅ High security standards
- ✅ Easy maintenance and monitoring

