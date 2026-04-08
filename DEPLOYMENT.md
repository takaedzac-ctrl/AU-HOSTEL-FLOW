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

1. **Install Firebase CLI:**
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase:**
   ```bash
   firebase login
   ```
   - This will open a browser window for authentication
   - Sign in with your Google account

3. **Initialize Firebase Hosting:**
   ```bash
   cd flutter_frontend
   firebase init hosting
   ```
   - Select "Use an existing project" and choose your Firebase project
   - When asked for the public directory, enter: `build/web`
   - Configure as a single-page app: **Yes**
   - Set up automatic builds: **No** (we'll build manually)

4. **Build web app:**
   ```bash
   cd flutter_frontend
   flutter build web --release
   ```
   - This creates optimized production files in `flutter_frontend/build/web/`
   - The build process may take several minutes
   - Look for "Built build/web" success message

5. **Deploy to Firebase:**
   ```bash
   firebase deploy
   ```
   - Firebase will upload your files and provide a hosting URL
   - The URL will look like: `https://your-project-id.web.app`
   - Copy this URL for updating your API configuration

6. **Update API URL (Important!):**
   - After deployment, get your Railway backend URL from the Railway dashboard
   - Update `flutter_frontend/lib/config.dart` with the Railway URL:
     ```dart
     const String apiUrl = 'https://your-railway-app.up.railway.app';
     ```
   - Rebuild and redeploy the frontend with the correct API URL

## Troubleshooting Firebase Deployment

**Common Issues:**

1. **"flutter build web --release" fails:**
   - Ensure you're in the `flutter_frontend` directory
   - Run `flutter pub get` first
   - Check for any compilation errors in your Flutter code

2. **Firebase login issues:**
   - Make sure you have Node.js and npm installed
   - Try `firebase logout` then `firebase login` again
   - Check that you're logged into the correct Google account

3. **Build files not found during deploy:**
   - Ensure the build completed successfully
   - Check that `flutter_frontend/build/web/` directory exists
   - Verify `firebase.json` has the correct public directory: `"public": "build/web"`

4. **CORS errors after deployment:**
   - Make sure your Railway backend allows requests from your Firebase domain
   - Check that the API URL in `config.dart` is correct

5. **App not loading:**
   - Check Firebase hosting logs in the Firebase console
   - Verify all asset files were uploaded correctly
   - Test the Firebase URL directly in a browser

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