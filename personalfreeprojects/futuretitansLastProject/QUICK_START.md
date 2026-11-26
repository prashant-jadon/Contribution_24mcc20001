# ⚡ Quick Start Guide - Future Titans Platform

## 1️⃣ Prerequisites Check

```bash
# Check Node.js version (should be 18+)
node --version

# Check npm
npm --version

# Check MongoDB is installed (for local development)
mongod --version
```

## 2️⃣ Clone & Setup (5 minutes)

```bash
# Navigate to project
cd futuretitansLastProject

# Create environment file
cp .env.example .env

# Edit .env with your credentials:
# nano .env  or  code .env
```

## 3️⃣ Get Your API Keys

### Razorpay
1. Go to https://dashboard.razorpay.com
2. Create account
3. Copy Key ID and Key Secret
4. Paste in .env as RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET

### Google Gemini API
1. Go to https://ai.google.dev
2. Create API key
3. Paste in .env as GEMINI_API_KEY

### MongoDB
For local development:
```bash
# macOS with Homebrew
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb-community

# Linux (Ubuntu)
sudo apt-get install -y mongodb

# Windows - Download from https://www.mongodb.com/try/download/community
```

OR use MongoDB Atlas (cloud):
1. Go to https://www.mongodb.com/cloud/atlas
2. Create free account
3. Create cluster
4. Copy connection string
5. Paste in .env as MONGODB_URI

## 4️⃣ Install Dependencies

```bash
# Backend
cd backend
npm install
cd ..

# Frontend
cd frontend
npm install
cd ..
```

## 5️⃣ Start Services

### Start Backend (Terminal 1)
```bash
cd backend
npm run dev
```
✅ Backend running at `http://localhost:5006`
📚 Swagger docs at `http://localhost:5006/api-docs`

### Start Frontend (Terminal 2)
```bash
cd frontend
npm run dev
```
✅ Frontend running at `http://localhost:3000`

## 6️⃣ Test the App

### Landing Page
- Open http://localhost:3000
- You should see the beautiful landing page

### Create Student Account
- Click "Get Started"
- Fill in signup form
- You'll be redirected to student dashboard

### Login as Admin
- Go to http://localhost:3000/login
- Email: `admin@futuretitans.com`
- Password: `admin123`
- Click on "/admin" in URL to access admin portal

## 📋 Quick Command Reference

```bash
# Start all services (if you have npm scripts)
npm run start:all  # May need setup

# Backend only
cd backend && npm run dev

# Frontend only
cd frontend && npm run dev

# Build for production
cd frontend && npm run build
cd backend && npm run build

# View Swagger API docs
# Open http://localhost:5006/api-docs in browser

# Stop services
# Press Ctrl+C in each terminal
```

## 🔧 Common Issues & Fixes

### "Cannot find module" error
```bash
# Delete node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

### MongoDB connection failed
```bash
# Start MongoDB
mongod

# Or use cloud MongoDB (Atlas)
# Update MONGODB_URI in .env
```

### Port already in use (3000 or 5006)
```bash
# Kill process using port 5006
lsof -i :5006
kill -9 <PID>

# Or change port in .env
PORT=5001
```

### Razorpay API not working
- Verify credentials in .env
- Check Razorpay account is active
- Make sure you're not in test mode with live credentials

## 📱 Testing Student Flow

1. **Signup**: Create account
2. **Payment**: Click "Pay Now" → Test with Razorpay test card:
   - Card: `4111 1111 1111 1111`
   - Expiry: Any future date
   - CVV: Any 3 digits
3. **Modules**: Browse available modules
4. **Learning**: Click module → Start chapter → Chat with AI
5. **Submit**: Fill idea submission form → Upload files → Submit

## 👨‍💼 Testing Admin Flow

1. **Login**: Use admin credentials above
2. **Dashboard**: View stats and KPIs
3. **Students**: Filter and view student list
4. **Modules**: Create/edit modules and chapters
5. **Submissions**: Review and score student ideas
6. **Analytics**: View detailed reports

## 🎨 Customize Design

Edit design system at: `frontend/styles/design-system.js`

```javascript
// Change primary color
primary: {
  red: '#YOUR_COLOR',
  darkRed: '#YOUR_COLOR',
  lightRed: '#YOUR_COLOR',
}
```

## 📊 Test Data

### Create test module
1. Go to Admin panel
2. Click "Create Module"
3. Fill details:
   - Title: "Entrepreneurship Basics"
   - Difficulty: "Beginner"
   - Enable AI Interaction
4. Add chapters with video URLs and content

### Test AI Chat
- Make sure chapter has subtitle text
- Enable AI Interaction
- Student clicks "Chat with Co-Founder"
- Have natural conversation
- Watch SSI score update

## 🚀 Next Steps

1. ✅ Verify all services running
2. ✅ Test signup/login
3. ✅ Create sample modules
4. ✅ Test payment flow
5. ✅ Test student dashboard
6. ✅ Test admin features
7. ✅ Test AI chat
8. ✅ Test submission form

## 📞 Help & Resources

- 📚 Full docs: `README.md`
- 📖 Setup guide: `IMPLEMENTATION_GUIDE.md`
- 🔌 API docs: `http://localhost:5006/api-docs`
- 🎨 Design system: `frontend/styles/design-system.js`

## ✨ You're All Set!

Start building amazing innovations! 🚀

For production deployment, see README.md section on deployment.

---

**Having issues?**
1. Check console for error messages
2. Verify all .env variables
3. Ensure MongoDB is running
4. Check API credentials
5. Review IMPLEMENTATION_GUIDE.md

