# Deployment Guide

## Prerequisites
1. GitHub repository
2. Railway account (for backend + database)
3. Firebase account (for frontend hosting)

## Backend Deployment (Railway)

1. Connect GitHub repo to Railway
2. Railway will auto-detect Dart and deploy
3. Add PostgreSQL database in Railway dashboard
4. Set environment variables:
   - `DATABASE_URL` - Railway provides this
   - `PORT` - 8080 (Railway sets this)

## Frontend Deployment (Firebase)

1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Initialize: `firebase init hosting`
4. Build web app: `flutter build web --release`
5. Deploy: `firebase deploy`

## Environment Variables

Create `.env` file in backend root:
```
DATABASE_URL=postgresql://...
PORT=8080
```

## Database Migration

SQLite data needs to be migrated to PostgreSQL. Use Railway's database tools or write a migration script.

## API URLs

Update frontend to use deployed backend URL instead of localhost.