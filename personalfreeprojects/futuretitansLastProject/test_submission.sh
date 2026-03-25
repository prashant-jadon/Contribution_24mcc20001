#!/bin/bash

# Test Submission API with curl
# Backend: http://localhost:5006
# Credentials: prashant@ft.com / 123123123

API_URL="http://localhost:5006/api"
EMAIL="prashant@ft.com"
PASSWORD="123123123"
PDF_FILE="IEEE_FinalVersion.pdf"

echo "🔐 Step 1: Login to get access token..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

echo "Login Response: $LOGIN_RESPONSE"

# Extract token (assuming response is JSON with accessToken field)
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Failed to get access token. Response: $LOGIN_RESPONSE"
  exit 1
fi

echo "✅ Token obtained: ${TOKEN:0:20}..."
echo ""

echo "📋 Step 2: Get user profile..."
PROFILE_RESPONSE=$(curl -s -X GET "$API_URL/auth/profile" \
  -H "Authorization: Bearer $TOKEN")
echo "Profile: $PROFILE_RESPONSE"
echo ""

echo "✅ Step 3: Check completion status..."
COMPLETION_RESPONSE=$(curl -s -X GET "$API_URL/auth/completion-status" \
  -H "Authorization: Bearer $TOKEN")
echo "Completion Status: $COMPLETION_RESPONSE"
echo ""

echo "📄 Step 4: Get existing submission (if any)..."
GET_SUBMISSION=$(curl -s -X GET "$API_URL/submission" \
  -H "Authorization: Bearer $TOKEN")
echo "Existing Submission: $GET_SUBMISSION"
echo ""

echo "📤 Step 5: Submit idea with PDF..."
SUBMIT_RESPONSE=$(curl -s -X POST "$API_URL/submission/submit" \
  -H "Authorization: Bearer $TOKEN" \
  -F "projectTitle=Test Innovation Project" \
  -F "primaryCategory=Technology" \
  -F "elevatorPitch=This is a test submission to verify the API works correctly" \
  -F "problemStatement=Testing the submission endpoint with PDF upload" \
  -F "solutionOverview=This solution addresses the testing needs" \
  -F "inspiration=Testing purposes" \
  -F "pdfFile=@$PDF_FILE")

echo "Submit Response: $SUBMIT_RESPONSE"
echo ""

if echo "$SUBMIT_RESPONSE" | grep -q "error"; then
  echo "❌ Submission failed. Check the error above."
else
  echo "✅ Submission successful!"
fi

