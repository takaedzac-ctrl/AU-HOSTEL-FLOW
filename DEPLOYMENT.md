# Deployment Guide

## Prerequisites
1. GitHub repository
2. Railway account (for backend + database)
3. Firebase account (for frontend hosting)

## Backend Deployment (Railway)

1. Connect GitHub repo to Railway
2. Railway will auto-detect Dart and deploy
3. **Add PostgreSQL database in Railway dashboard:**
   - Go to your Railway project dashboard
   - Click "Add Service" → "Database" → "PostgreSQL"
   - Choose a name for your database (e.g., "au-hostel-db")
   - Click "Create Database"
   - Wait for the database to be provisioned (usually takes 1-2 minutes)
   - Once created, go to the "Variables" tab of your database service
   - Copy the `DATABASE_URL` value
   - **Link database to your backend service:**
     - Go to your backend service (the one connected to GitHub)
     - Click on the "Variables" tab
     - The `DATABASE_URL` should automatically appear (Railway links services automatically)
     - If it doesn't appear, click "Add Variable" and paste the DATABASE_URL from the database service
4. Set environment variables:
   - `DATABASE_URL` - Railway provides this automatically
   - `PORT` - 8080 (Railway sets this automatically)

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

Your current system uses SQLite, but Railway provides PostgreSQL. Here's how to migrate:

1. **Access Railway PostgreSQL:**
   - In Railway dashboard, go to your PostgreSQL service
   - Click "Connect" tab
   - Use the connection details to connect via Railway's built-in database browser or external tools

2. **Option 1: Manual Migration (Recommended for small datasets)**
   - Export data from your local SQLite database
   - Use Railway's database browser to create tables and import data
   - Or use tools like `pgloader` or write a custom migration script

3. **Option 2: Automated Migration**
   - Create a migration script that reads from SQLite and writes to PostgreSQL
   - Run the script locally with both database connections
   - Update your backend code to use PostgreSQL instead of SQLite

4. **Update Backend Code:**
   - Modify `lib/storage/data_storage.dart` to use PostgreSQL instead of SQLite
   - Update database connection logic to use `DATABASE_URL` environment variable
   - Test locally with a PostgreSQL database before deploying

## API URLs

Update frontend to use deployed backend URL instead of localhost.