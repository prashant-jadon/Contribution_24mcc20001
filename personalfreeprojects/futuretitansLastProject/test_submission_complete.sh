#!/bin/bash

# Complete Submission API Test
# Backend: http://localhost:5006
# Credentials: prashant@ft.com / 123123123

API_URL="http://localhost:5006/api"
EMAIL="prashant@ft.com"
PASSWORD="123123123"
PDF_FILE="IEEE_FinalVersion.pdf"

echo "=========================================="
echo "🧪 Testing Submission API"
echo "=========================================="
echo ""

# Step 1: Login
echo "🔐 Step 1: Login..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

TOKEN=$(echo $LOGIN_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin).get('accessToken', ''))" 2>/dev/null)

if [ -z "$TOKEN" ]; then
  echo "❌ Login failed!"
  echo "Response: $LOGIN_RESPONSE"
  exit 1
fi

echo "✅ Login successful"
echo "Token: ${TOKEN:0:30}..."
echo ""

# Step 2: Get Profile
echo "👤 Step 2: Get User Profile..."
PROFILE=$(curl -s -X GET "$API_URL/auth/profile" \
  -H "Authorization: Bearer $TOKEN")
echo "$PROFILE" | python3 -m json.tool 2>/dev/null || echo "$PROFILE"
echo ""

# Step 3: Check Completion Status
echo "✅ Step 3: Check Completion Status..."
COMPLETION=$(curl -s -X GET "$API_URL/auth/completion-status" \
  -H "Authorization: Bearer $TOKEN")
echo "$COMPLETION" | python3 -m json.tool 2>/dev/null || echo "$COMPLETION"
echo ""

# Step 4: Get Existing Submission
echo "📄 Step 4: Get Existing Submission..."
GET_SUBMISSION=$(curl -s -w "\nHTTP Status: %{http_code}\n" -X GET "$API_URL/submission" \
  -H "Authorization: Bearer $TOKEN")
echo "$GET_SUBMISSION"
echo ""

# Step 5: Submit Idea
echo "📤 Step 5: Submit Idea with PDF..."
if [ ! -f "$PDF_FILE" ]; then
  echo "❌ PDF file not found: $PDF_FILE"
  exit 1
fi

SUBMIT_RESPONSE=$(curl -s -w "\nHTTP Status: %{http_code}\n" -X POST "$API_URL/submission/submit" \
  -H "Authorization: Bearer $TOKEN" \
  -F "projectTitle=IEEE Innovation Project Test" \
  -F "primaryCategory=Technology" \
  -F "secondaryCategory=Education" \
  -F "elevatorPitch=This is a test submission using the IEEE PDF document to verify the submission API works correctly" \
  -F "problemStatement=Testing the submission endpoint with PDF upload functionality to ensure all APIs are working properly" \
  -F "existingSolutions=Manual testing and verification" \
  -F "solutionOverview=Automated API testing solution that validates submission workflow including file uploads and data persistence" \
  -F "prototypeDescription=This is a test prototype for API validation" \
  -F "userTypes=Developers and QA Engineers" \
  -F "reachStrategy=Direct API testing" \
  -F "impactDescription=Ensures API reliability and functionality" \
  -F "businessModel=Testing model" \
  -F "teamSkills=API Testing, Backend Development" \
  -F "wantToLearn=API validation techniques" \
  -F "improvementPlan=Continue testing and validation" \
  -F "expectedShortTermOutcomes=Successful API validation" \
  -F "longTermVision=Reliable submission system" \
  -F "successMetrics=API response codes and data persistence" \
  -F "resourcesNeeded=Test environment" \
  -F "implementationTimeline=Immediate" \
  -F "risks=None for testing" \
  -F "primaryBeneficiaries=Development team" \
  -F "keyStakeholders=QA and Development" \
  -F "sustainability=Ongoing testing" \
  -F "ethicalConsiderations=None for testing" \
  -F "inspiration=API Testing" \
  -F "previousWork=Previous test submissions" \
  -F "pdfFile=@$PDF_FILE")

echo "$SUBMIT_RESPONSE"
echo ""

# Step 6: Verify Submission
echo "🔍 Step 6: Verify Submission was saved..."
VERIFY=$(curl -s -X GET "$API_URL/submission" \
  -H "Authorization: Bearer $TOKEN")
echo "$VERIFY" | python3 -m json.tool 2>/dev/null || echo "$VERIFY"
echo ""

echo "=========================================="
echo "✅ Test Complete!"
echo "=========================================="

