@echo off
echo ========================================================
echo DAK SOCIAL - SUPABASE EDGE FUNCTION DEPLOYMENT
echo ========================================================
echo This script will deploy your automated push notification 
echo backend to your Supabase project.
echo.
echo Make sure you have the Supabase CLI installed globally:
echo npm install -g supabase
echo.
pause

echo.
echo Step 1: Logging in to Supabase...
echo A browser window will open. Please log in and authorize the CLI.
call npx supabase login

echo.
echo Step 2: Linking to your project (lznxtbnqwaryqkyxfwgy)...
call npx supabase link --project-ref lznxtbnqwaryqkyxfwgy

echo.
echo Step 3: Setting Firebase Secrets in Supabase...
echo Please ensure you have created a supabase/.env.local file with your Firebase credentials!
echo (FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY, FCM_PROJECT_ID)
call npx supabase secrets set --env-file supabase/.env.local

echo.
echo Step 4: Deploying the Edge Function...
call npx supabase functions deploy send_auto_push --no-verify-jwt

echo.
echo ========================================================
echo DEPLOYMENT COMPLETE!
echo ========================================================
echo Remember to run the supabase\push_triggers.sql file
echo in your Supabase SQL Editor online to activate the automation!
pause
