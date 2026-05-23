#!/usr/bin/env bash
# Enterprise smoke test: Chat, Spaces, devices, subscriptions, privacy audit, calls.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
bash "$ROOT/mac/publshr/scripts/verify-chat-spaces.sh"

SUPABASE_URL="${SUPABASE_URL:-https://lboesdtsrqfvosznjpdy.supabase.co}"
SUPABASE_KEY="${SUPABASE_KEY:-sb_publishable_mHARlRkK4iHkkn9wn_-uAw_EkW-jRXP}"
TEST_EMAIL="${TEST_EMAIL:-publshr-test-1779384952@mailinator.com}"
TEST_PASSWORD="${TEST_PASSWORD:-TestPass123!}"

signin=$(curl -sf -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")
token=$(echo "$signin" | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
user_id=$(echo "$signin" | python3 -c "import sys,json; print(json.load(sys.stdin)['user']['id'])")

check_table() {
  local table=$1
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" \
    "$SUPABASE_URL/rest/v1/${table}?select=id&limit=1" \
    -H "apikey: $SUPABASE_KEY" \
    -H "Authorization: Bearer $token")
  if [[ "$code" != "200" ]]; then
    echo "FAIL: $table HTTP $code (expected 200)"
    exit 1
  fi
  echo "OK: $table"
}

echo "6. Enterprise tables (RLS + schema)"
check_table "subscription_plans"
check_table "device_registrations"
check_table "privacy_audit_events"
check_table "call_rooms"
check_table "whiteboards"
check_table "chat_scheduled_messages"
check_table "projects"
check_table "planner_items"

echo "7. Device registration upsert"
device_key="verify-$(date +%s)"
curl -sf -X POST "$SUPABASE_URL/rest/v1/device_registrations" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $token" \
  -H "Content-Type: application/json" \
  -H "Prefer: resolution=merge-duplicates" \
  -d "{\"user_id\":\"$user_id\",\"device_key\":\"$device_key\",\"device_name\":\"CI verify\",\"platform\":\"linux\",\"app_version\":\"verify\"}" >/dev/null
echo "   device registered"

echo "8. Privacy audit insert + read-back"
curl -sf -X POST "$SUPABASE_URL/rest/v1/privacy_audit_events" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $token" \
  -H "Content-Type: application/json" \
  -d "{\"user_id\":\"$user_id\",\"event_type\":\"verify\",\"detail\":\"enterprise smoke test\"}" >/dev/null
count=$(curl -sf "$SUPABASE_URL/rest/v1/privacy_audit_events?user_id=eq.$user_id&event_type=eq.verify&select=id" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $token" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")
if [[ "$count" -lt 1 ]]; then
  echo "FAIL: privacy audit read-back"
  exit 1
fi
echo "   privacy audit readable"

echo "ALL ENTERPRISE CHECKS PASSED"
