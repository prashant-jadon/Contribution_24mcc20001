# 🚀 **Production Deployment Guide - Future Titans Platform**

## 📋 **Pre-Deployment Checklist**

### ✅ **Backend Ready**
- [x] All API endpoints functional
- [x] Database models created
- [x] Authentication system working
- [x] Payment integration complete
- [x] AI engine operational
- [x] File upload system ready
- [x] Error handling implemented
- [x] Rate limiting configured
- [x] Health checks available

### ✅ **Frontend Ready**
- [x] All pages created
- [x] Admin portal complete
- [x] Student portal complete
- [x] Responsive design
- [x] API integration working
- [x] Authentication flows
- [x] Payment integration
- [x] File upload UI

---

## 🌐 **Deployment Options**

### **Option 1: Railway (Recommended)**

#### **Backend Deployment**
```bash
# 1. Install Railway CLI
npm install -g @railway/cli

# 2. Login to Railway
railway login

# 3. Deploy backend
cd backend
railway init
railway up
```

#### **Frontend Deployment**
```bash
# Deploy to Vercel
cd frontend
npx vercel --prod
```

### **Option 2: Heroku + Vercel**

#### **Backend (Heroku)**
```bash
# 1. Create Heroku app
heroku create future-titans-backend

# 2. Set environment variables
heroku config:set MONGODB_URI=your_mongodb_atlas_uri
heroku config:set JWT_SECRET=your_jwt_secret
heroku config:set RAZORPAY_KEY_ID=your_razorpay_key
heroku config:set GEMINI_API_KEY=your_gemini_key

# 3. Deploy
git push heroku main
```

#### **Frontend (Vercel)**
```bash
# 1. Install Vercel CLI
npm i -g vercel

# 2. Deploy
cd frontend
vercel --prod
```

### **Option 3: AWS/DigitalOcean**

#### **Backend (EC2/Droplet)**
```bash
# 1. Setup server
sudo apt update
sudo apt install nodejs npm nginx

# 2. Clone and setup
git clone your-repo
cd backend
npm install
npm run build

# 3. Setup PM2
npm install -g pm2
pm2 start src/index.js --name "future-titans-api"
pm2 startup
pm2 save
```

---

## 🔧 **Environment Configuration**

### **Backend Environment Variables**

Create `.env` file in backend:
```env
# Production Database
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/future-titans

# JWT Secrets (Generate strong 256-bit keys)
JWT_SECRET=your-production-jwt-secret-256-bit
JWT_REFRESH_SECRET=your-production-refresh-secret-256-bit

# Razorpay Live Keys
RAZORPAY_KEY_ID=rzp_live_your_live_key
RAZORPAY_KEY_SECRET=your_live_secret

# Gemini API
GEMINI_API_KEY=your_gemini_api_key

# Production Settings
NODE_ENV=production
PORT=5000
FRONTEND_URL=https://your-domain.com

# Security
BCRYPT_ROUNDS=12
RATE_LIMIT_MAX_REQUESTS=50
```

### **Frontend Environment Variables**

Create `.env.local` file in frontend:
```env
NEXT_PUBLIC_API_URL=https://your-backend-domain.com/api
NEXT_PUBLIC_RAZORPAY_KEY_ID=rzp_live_your_live_key
```

---

## 🗄️ **Database Setup**

### **MongoDB Atlas (Recommended)**

1. **Create Cluster:**
   - Go to [MongoDB Atlas](https://cloud.mongodb.com)
   - Create new cluster
   - Choose region closest to your users

2. **Setup Database:**
   ```bash
   # Connect to your cluster and create database
   use future-titans
   
   # Create indexes for performance
   db.users.createIndex({ email: 1 }, { unique: true })
   db.modules.createIndex({ isPublished: 1 })
   db.aichats.createIndex({ studentId: 1, chapterId: 1 })
   db.ideasubmissions.createIndex({ studentId: 1 })
   ```

3. **Security:**
   - Enable authentication
   - Create database user
   - Whitelist IP addresses
   - Enable encryption at rest

---

## 🔐 **Security Hardening**

### **Backend Security**

1. **Update CORS:**
   ```javascript
   app.use(cors({
     origin: ['https://your-domain.com'],
     credentials: true,
     optionsSuccessStatus: 200
   }));
   ```

2. **Add Security Headers:**
   ```javascript
   app.use(helmet({
     contentSecurityPolicy: {
       directives: {
         defaultSrc: ["'self'"],
         styleSrc: ["'self'", "'unsafe-inline'"],
         scriptSrc: ["'self'", "checkout.razorpay.com"],
         imgSrc: ["'self'", "data:", "https:"],
       },
     },
   }));
   ```

3. **Rate Limiting:**
   ```javascript
   const strictLimiter = rateLimit({
     windowMs: 15 * 60 * 1000, // 15 minutes
     max: 20, // limit each IP to 20 requests per windowMs
   });
   
   app.use('/api/auth', strictLimiter);
   app.use('/api/payment', strictLimiter);
   ```

### **Frontend Security**

1. **Next.js Config:**
   ```javascript
   const nextConfig = {
     poweredByHeader: false,
     compress: true,
     generateEtags: false,
     httpAgentOptions: {
       keepAlive: true,
     },
   };
   ```

2. **Content Security Policy:**
   Add to `next.config.js`:
   ```javascript
   const securityHeaders = [
     {
       key: 'X-DNS-Prefetch-Control',
       value: 'on'
     },
     {
       key: 'Strict-Transport-Security',
       value: 'max-age=63072000; includeSubDomains; preload'
     },
     {
       key: 'X-Frame-Options',
       value: 'DENY'
     }
   ];
   ```

---

## ⚡ **Performance Optimization**

### **Backend Optimization**

1. **Database Indexing:**
   ```javascript
   // Add to your models
   userSchema.index({ email: 1 });
   moduleSchema.index({ isPublished: 1, difficulty: 1 });
   aiChatSchema.index({ studentId: 1, chapterId: 1 });
   ```

2. **Caching:**
   ```javascript
   // Add Redis for caching
   const redis = require('redis');
   const client = redis.createClient(process.env.REDIS_URL);
   
   // Cache frequently accessed data
   app.get('/api/modules', cache('5 minutes'), getModules);
   ```

3. **Compression:**
   ```javascript
   const compression = require('compression');
   app.use(compression());
   ```

### **Frontend Optimization**

1. **Image Optimization:**
   ```javascript
   // next.config.js
   module.exports = {
     images: {
       domains: ['your-cdn-domain.com'],
       formats: ['image/webp', 'image/avif'],
     },
   };
   ```

2. **Bundle Analysis:**
   ```bash
   npm install --save-dev @next/bundle-analyzer
   
   # Analyze bundle
   ANALYZE=true npm run build
   ```

---

## 📊 **Monitoring & Analytics**

### **Health Monitoring**

1. **Uptime Monitoring:**
   - Use UptimeRobot or Pingdom
   - Monitor `/health` endpoint
   - Set up alerts for downtime

2. **Error Tracking:**
   ```javascript
   // Add Sentry for error tracking
   const Sentry = require('@sentry/node');
   
   Sentry.init({
     dsn: process.env.SENTRY_DSN,
   });
   ```

3. **Performance Monitoring:**
   ```javascript
   // Add performance monitoring
   const newrelic = require('newrelic');
   ```

### **Analytics Setup**

1. **Google Analytics:**
   ```javascript
   // Add to frontend
   import { GoogleAnalytics } from 'nextjs-google-analytics';
   
   export default function App({ Component, pageProps }) {
     return (
       <>
         <GoogleAnalytics trackPageViews />
         <Component {...pageProps} />
       </>
     );
   }
   ```

---

## 🔄 **CI/CD Pipeline**

### **GitHub Actions**

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]

jobs:
  deploy-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to Railway
        run: |
          npm install -g @railway/cli
          railway login --token ${{ secrets.RAILWAY_TOKEN }}
          railway up --service backend

  deploy-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to Vercel
        run: |
          npm install -g vercel
          vercel --token ${{ secrets.VERCEL_TOKEN }} --prod
```

---

## 🧪 **Testing in Production**

### **Smoke Tests**

```bash
# Test API endpoints
curl https://your-api-domain.com/health
curl https://your-api-domain.com/api/status

# Test authentication
curl -X POST https://your-api-domain.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@futuretitans.com","password":"admin123"}'
```

### **Load Testing**

```bash
# Install artillery
npm install -g artillery

# Create load test
artillery quick --count 10 --num 100 https://your-api-domain.com/health
```

---

## 📈 **Scaling Considerations**

### **Horizontal Scaling**

1. **Load Balancer:**
   - Use Nginx or AWS ALB
   - Distribute traffic across multiple instances

2. **Database Scaling:**
   - MongoDB replica sets
   - Read replicas for analytics
   - Sharding for large datasets

3. **CDN Setup:**
   - CloudFlare for static assets
   - Image optimization
   - Global edge caching

### **Vertical Scaling**

1. **Server Resources:**
   - Monitor CPU/Memory usage
   - Scale up during peak hours
   - Auto-scaling groups

2. **Database Optimization:**
   - Query optimization
   - Index tuning
   - Connection pooling

---

## 🚨 **Backup & Recovery**

### **Database Backups**

```bash
# Automated MongoDB backups
mongodump --uri="mongodb+srv://user:pass@cluster.mongodb.net/future-titans" --out=/backups/$(date +%Y%m%d)

# Schedule with cron
0 2 * * * /usr/local/bin/mongodump --uri="$MONGODB_URI" --out=/backups/$(date +\%Y\%m\%d)
```

### **File Backups**

```bash
# Backup uploaded files
aws s3 sync /app/uploads s3://your-backup-bucket/uploads/$(date +%Y%m%d)
```

---

## 📞 **Support & Maintenance**

### **Log Management**

```javascript
// Structured logging
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});
```

### **Health Checks**

```javascript
// Advanced health check
app.get('/health', async (req, res) => {
  const health = {
    status: 'OK',
    timestamp: new Date().toISOString(),
    checks: {
      database: await checkDatabase(),
      redis: await checkRedis(),
      external_apis: await checkExternalAPIs()
    }
  };
  
  const isHealthy = Object.values(health.checks).every(check => check.status === 'OK');
  res.status(isHealthy ? 200 : 503).json(health);
});
```

---

## ✅ **Final Deployment Checklist**

- [ ] Environment variables configured
- [ ] Database migrations run
- [ ] SSL certificates installed
- [ ] Domain DNS configured
- [ ] CDN setup complete
- [ ] Monitoring tools active
- [ ] Backup systems running
- [ ] Load testing completed
- [ ] Security scan passed
- [ ] Admin user created
- [ ] Documentation updated

---

## 🎉 **Go Live!**

Your Future Titans platform is now ready for production! 

**Live URLs:**
- Frontend: https://your-domain.com
- Backend API: https://api.your-domain.com
- Admin Panel: https://your-domain.com/admin

**Admin Credentials:**
- Email: admin@futuretitans.com
- Password: [Set secure password]

---

**🚀 Congratulations! Your platform is now serving the next generation of innovators worldwide! 🌍**
