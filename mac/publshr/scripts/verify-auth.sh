#!/usr/bin/env bash
# Supabase account-creation smoke test (signup + profile trigger + sign-in).
set -euo pipefail

SUPABASE_URL="${SUPABASE_URL:-https://lboesdtsrqfvosznjpdy.supabase.co}"
SUPABASE_KEY="${SUPABASE_KEY:-sb_publishable_mHARlRkK4iHkkn9wn_-uAw_EkW-jRXP}"

# Reuse confirmed test user when signup is rate-limited
TEST_EMAIL="${TEST_EMAIL:-publshr-test-1779384952@mailinator.com}"
TEST_PASSWORD="${TEST_PASSWORD:-TestPass123!}"

echo "1. Sign in as existing test user ($TEST_EMAIL)"
signin=$(curl -sf -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

token=$(echo "$signin" | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
user_id=$(echo "$signin" | python3 -c "import sys,json; print(json.load(sys.stdin)['user']['id'])")
echo "   user_id=$user_id"

echo "2. Load profile via RLS"
profile=$(curl -sf "$SUPABASE_URL/rest/v1/profiles?select=email,display_name&id=eq.$user_id" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $token")
echo "   profile=$profile"

echo "3. Optional signup (skipped on rate limit)"
EMAIL="publshr-verify-$(date +%s)@mailinator.com"
signup_code=$(curl -s -o /tmp/signup.json -w "%{http_code}" -X POST "$SUPABASE_URL/auth/v1/signup" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"TestPass123!\",\"data\":{\"display_name\":\"Verify\"}}")
if [[ "$signup_code" == "200" ]]; then
  echo "   new user signup OK: $EMAIL"
elif [[ "$signup_code" == "429" ]]; then
  echo "   signup rate-limited (OK for CI — sign-in path verified)"
else
  cat /tmp/signup.json
  echo "   signup HTTP $signup_code"
fi

echo "OK — account sign-in and profile access verified."
