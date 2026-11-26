# 🚀 Future Titans Innovation Challenge Platform

> **Production-ready, AI-powered learning platform for empowering the next generation of innovators**

A complete full-stack system combining AI-driven mentorship, structured modules, and competition management for aspiring entrepreneurs.

## ✨ Key Features

### 🧑‍🎓 Student Portal
- **Smart Registration & Payment Flow** - Seamless Razorpay integration
- **Structured Learning Modules** - Video, audio, PDF, and text-based content
- **AI Co-Founder Chat** - Personalized mentorship powered by Gemini API
- **SURGE Framework Assessment** - 5-dimensional mindset evaluation
- **SSI Score Tracking** - Real-time Solution-Seeking Index
- **Idea Submission Portal** - Long-form competition entry
- **File Uploads** - PDF proposals and video pitches

### 👨‍💼 Admin Portal
- **Student Management** - Complete CRM with filters and analytics
- **Module Builder** - Create courses with multimedia content
- **AI Prompt Management** - Customize AI behavior and scoring
- **Submission Reviewing** - Evaluation and scoring interface
- **Advanced Analytics** - Student insights, trends, and reports
- **Payment Tracking** - Revenue and transaction management

### 🤖 AI Engine (SURGE Framework)
- **Conversational Learning** - Natural dialogue-based assessment
- **Context Awareness** - Uses module content and conversation history
- **Multi-dimensional Scoring** - Self-Awareness, Understanding, Resilience, Growth, Leadership
- **Behavioral Analysis** - Creativity, clarity, decision-making quality detection
- **Adaptive Responses** - Learns from student interactions

### 💳 Payments
- **Razorpay Integration** - Secure INR transactions
- **Webhook Verification** - Real-time payment validation
- **Status Tracking** - Student payment history
- **Refund Management** - Admin refund capabilities

## 🏗️ Tech Stack

### Backend
- **Runtime**: Node.js with ES6 modules
- **Framework**: Express.js
- **Database**: MongoDB
- **Authentication**: JWT + Refresh tokens + bcrypt
- **AI**: Google Gemini API
- **Payments**: Razorpay
- **File Upload**: Multer
- **Rate Limiting**: Express Rate Limit
- **API Docs**: Swagger/OpenAPI
- **Validation**: Joi
- **Security**: Helmet, CORS

### Frontend
- **Framework**: Next.js 14 (App Router)
- **Styling**: Tailwind CSS 3.3
- **UI Components**: Shadcn/ui (Radix UI)
- **State Management**: Zustand
- **HTTP Client**: Axios
- **Forms**: React Hook Form
- **Icons**: Lucide React
- **Charts**: Recharts
- **Animations**: Framer Motion
- **Storage**: JS Cookie

## 📁 Project Structure

```
futuretitansLastProject/
├── backend/                          # Express.js backend
│   ├── src/
│   │   ├── config/                   # Database configuration
│   │   ├── models/                   # MongoDB schemas
│   │   ├── controllers/              # Route handlers
│   │   ├── middleware/               # Auth, error, rate limiting
│   │   ├── routes/                   # API endpoints
│   │   ├── services/                 # AI engine, payments
│   │   └── index.js                  # Server entry point
│   ├── uploads/                      # User file uploads (gitignored)
│   └── package.json
├── frontend/                         # Next.js frontend
│   ├── app/                          # App Router structure
│   │   ├── (auth)/                   # Auth pages
│   │   ├── (student)/                # Student portal
│   │   ├── admin/                    # Admin portal
│   │   ├── layout.js                 # Root layout
│   │   ├── page.js                   # Landing page
│   │   └── globals.css               # Global styles
│   ├── components/                   # Reusable React components
│   ├── lib/                          # Utilities (API, auth)
│   ├── store/                        # Zustand stores
│   ├── styles/                       # Design system
│   ├── public/                       # Static assets
│   ├── tailwind.config.js           # Tailwind configuration
│   └── package.json
├── .env.example                      # Environment template
├── .gitignore                        # Git ignore rules
├── IMPLEMENTATION_GUIDE.md           # Detailed setup guide
└── README.md                         # This file
```

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- MongoDB 5+
- Razorpay account
- Google Gemini API key

### Installation

```bash
# Clone and setup
git clone <repo>
cd futuretitansLastProject

# Backend setup
cd backend
npm install
cd ..

# Frontend setup
cd frontend
npm install
cd ..

# Create environment files
cp .env.example .env

# Edit .env with your credentials:
# - MONGODB_URI
# - JWT_SECRET
# - RAZORPAY_KEY_ID & KEY_SECRET
# - GEMINI_API_KEY
```

### Running the Application

```bash
# Terminal 1: Start backend
cd backend
npm run dev
# Available at http://localhost:5006
# Swagger docs at http://localhost:5006/api-docs

# Terminal 2: Start frontend
cd frontend
npm run dev
# Available at http://localhost:3000
```

## 📊 Database Models

### User
```javascript
{
  name, email, phone, school, city, country,
  password (hashed), role, isPaid,
  razorpayOrderId, razorpayPaymentId, paymentDate,
  ssiScore, ssiBreakdown {selfAwareness, understandingOpportunities, resilience, growthExecution, entrepreneurialLeadership},
  modulesProgress[], ideaSubmission
}
```

### Module
```javascript
{
  title, description, difficulty,
  coverImage, estimatedCompletionTime,
  aiInteractionEnabled, chapters[],
  isPublished, createdBy, timestamps
}
```

### AIChat
```javascript
{
  studentId, chapterId, moduleId,
  conversation[], ssiScore, interactionMetrics,
  isCompleted, timestamps
}
```

### IdeaSubmission
```javascript
{
  studentId, teamMembers[],
  projectTitle, primaryCategory, secondaryCategory,
  elevatorPitch, problemStatement, solutionOverview,
  businessModel, userTypes, reachStrategy,
  sustainability, ethicalConsiderations,
  pdfFile, videoFile,
  submissionStatus, adminScore, adminNotes,
  timestamps
}
```

## 🔑 API Endpoints

### Authentication
- `POST /api/auth/signup` - Register new user
- `POST /api/auth/login` - Login
- `POST /api/auth/refresh` - Refresh access token
- `GET /api/auth/profile` - Get user profile
- `PUT /api/auth/profile` - Update profile

### Payments
- `POST /api/payment/initiate` - Create Razorpay order
- `POST /api/payment/verify` - Verify payment webhook
- `GET /api/payment/status` - Check payment status

### Modules
- `GET /api/modules` - List all modules
- `GET /api/modules/:id` - Get module details
- `POST /api/modules` - Create module (admin)
- `PUT /api/modules/:id` - Update module (admin)
- `DELETE /api/modules/:id` - Delete module (admin)

### AI Chat
- `POST /api/chat/:moduleId/chapters/:chapterId/message` - Send message
- `GET /api/chat/:moduleId/chapters/:chapterId/history` - Get chat history
- `POST /api/chat/:moduleId/chapters/:chapterId/complete` - Mark chapter complete
- `GET /api/chat/ssi` - Get SSI score
- `GET /api/chat/report` - Get student report

### Submissions
- `POST /api/submission/draft` - Save draft
- `POST /api/submission/submit` - Submit idea
- `GET /api/submission` - Get user submission
- `GET /api/submission/admin/all` - List submissions (admin)
- `GET /api/submission/admin/:id` - Get submission details (admin)
- `PUT /api/submission/admin/:id/score` - Score submission (admin)

### Admin
- `GET /api/admin/dashboard` - Dashboard stats
- `GET /api/admin/students` - List students with filters
- `GET /api/admin/analytics` - Analytics data
- `GET /api/admin/export/students` - Export student data

## 🎨 Design System

The platform uses a sophisticated Apple-inspired design with red/white/gold theme:

```javascript
// Access design system constants
import { colors, typography, spacing, shadows } from '@/styles/design-system';

// Colors available:
// - Primary: Red (#DC2626)
// - Accent: Gold (#D97706)
// - Neutral: Grays
// - Semantic: Success, Warning, Error, Info
```

## 🔐 Security Features

- ✅ Password hashing with bcrypt (10 salt rounds)
- ✅ JWT tokens with short expiration
- ✅ Refresh token rotation
- ✅ Rate limiting (15 auth attempts/15min, 100 general/15min)
- ✅ CORS validation
- ✅ Helmet security headers
- ✅ Input validation with Joi
- ✅ MongoDB injection prevention
- ✅ File upload validation
- ✅ Secure error handling (no stack traces in production)

## 📈 Scalability for 10,000 Users

- **Database**: MongoDB Atlas for horizontal scaling
- **Caching**: Redis for sessions and module caching
- **CDN**: CloudFront for static assets
- **Load Balancing**: Nginx reverse proxy
- **Connection Pooling**: Database connection optimization
- **S3 Storage**: Cloud storage for uploads
- **API Rate Limiting**: Prevent abuse
- **Async Jobs**: Bull Queue for background tasks
- **Monitoring**: DataDog for system observability

## 👨‍💼 Admin Credentials

**For Development/Demo:**
- **Email**: admin@futuretitans.com
- **Password**: admin123

⚠️ **Change these in production!**

## 🧪 Testing

```bash
# Backend
cd backend
npm test

# Frontend
cd frontend
npm test
```

## 📚 API Documentation

Swagger documentation is automatically generated and available at:
```
http://localhost:5006/api-docs
```

## 🌍 Deployment

### Backend (Railway/Heroku)
```bash
git push heroku main
```

### Frontend (Vercel)
```bash
npm install -g vercel
vercel
```

### Docker
```bash
docker-compose up --build
```

## 📝 Environment Variables

See `.env.example` for complete list:

```env
# Core
MONGODB_URI=mongodb://localhost:27017/future-titans
NODE_ENV=development
PORT=5006

# Authentication
JWT_SECRET=your_secret_key_here
JWT_REFRESH_SECRET=your_refresh_secret
JWT_EXPIRE=15m
JWT_REFRESH_EXPIRE=7d

# Payments
RAZORPAY_KEY_ID=your_key_id
RAZORPAY_KEY_SECRET=your_key_secret

# AI
GEMINI_API_KEY=your_gemini_api_key

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:5006/api
```

## 🐛 Troubleshooting

### MongoDB Connection Issues
```bash
# Check if MongoDB is running
mongod --version

# Start MongoDB service
sudo service mongod start
```

### Port Already in Use
```bash
# Backend (change PORT in .env)
lsof -i :5006
kill -9 <PID>

# Frontend (change port)
npm run dev -- -p 3001
```

### Gemini API Rate Limit
- Implement request queuing with Bull
- Add exponential backoff retry logic
- Cache responses when possible

## 📞 Support

For issues or questions:
1. Check the IMPLEMENTATION_GUIDE.md
2. Review API documentation at /api-docs
3. Check environment variables
4. Review console logs for errors

## 🤝 Contributing

1. Create feature branch: `git checkout -b feature/YourFeature`
2. Commit changes: `git commit -m 'Add feature'`
3. Push to branch: `git push origin feature/YourFeature`
4. Submit pull request

## 📄 License

This project is proprietary software for Future Titans Innovation Challenge.

## 🎓 Learning Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [Express.js Guide](https://expressjs.com/)
- [MongoDB Manual](https://docs.mongodb.com/manual/)
- [Tailwind CSS](https://tailwindcss.com/)
- [Google Gemini API](https://ai.google.dev/)
- [Razorpay Documentation](https://razorpay.com/docs)

---

**Built with ❤️ for innovators everywhere**

✨ *Transform ideas into impact with Future Titans* ✨

