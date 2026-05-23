#!/usr/bin/env bash
# Smoke test: authenticated user can read chat channels and spaces (RLS + schema).
set -euo pipefail

SUPABASE_URL="${SUPABASE_URL:-https://lboesdtsrqfvosznjpdy.supabase.co}"
SUPABASE_KEY="${SUPABASE_KEY:-sb_publishable_mHARlRkK4iHkkn9wn_-uAw_EkW-jRXP}"
TEST_EMAIL="${TEST_EMAIL:-publshr-test-1779384952@mailinator.com}"
TEST_PASSWORD="${TEST_PASSWORD:-TestPass123!}"

echo "1. Sign in ($TEST_EMAIL)"
signin=$(curl -sf -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")
token=$(echo "$signin" | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
user_id=$(echo "$signin" | python3 -c "import sys,json; print(json.load(sys.stdin)['user']['id'])")

echo "2. Workspace memberships"
members=$(curl -sf "$SUPABASE_URL/rest/v1/workspace_members?user_id=eq.$user_id&select=workspace_id,role" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $token")
echo "   $members"
ws_id=$(echo "$members" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['workspace_id'] if d else '')" 2>/dev/null || true)
if [[ -z "$ws_id" ]]; then
  echo "   No workspace — creating via RPC"
  ws=$(curl -sf -X POST "$SUPABASE_URL/rest/v1/rpc/create_workspace" \
    -H "apikey: $SUPABASE_KEY" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d '{"p_name":"Verify Workspace"}')
  ws_id=$(echo "$ws" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
  sleep 1
fi
echo "   workspace_id=$ws_id"

echo "3. Chat channels"
channels=$(curl -sf "$SUPABASE_URL/rest/v1/chat_channels?workspace_id=eq.$ws_id&select=id,name&limit=5" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $token")
echo "   channels=$channels"

echo "4. Spaces"
spaces=$(curl -sf "$SUPABASE_URL/rest/v1/spaces?workspace_id=eq.$ws_id&select=id,name&limit=5" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $token")
space_count=$(echo "$spaces" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo 0)
if [[ "$space_count" == "0" ]]; then
  echo "   No space — creating General"
  curl -sf -X POST "$SUPABASE_URL/rest/v1/spaces" \
    -H "apikey: $SUPABASE_KEY" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=representation" \
    -d "{\"workspace_id\":\"$ws_id\",\"name\":\"General\",\"type\":\"project\",\"owner_id\":\"$user_id\"}" >/dev/null
  spaces=$(curl -sf "$SUPABASE_URL/rest/v1/spaces?workspace_id=eq.$ws_id&select=id,name&limit=5" \
    -H "apikey: $SUPABASE_KEY" \
    -H "Authorization: Bearer $token")
fi
echo "   spaces=$spaces"

echo "5. Documents table"
docs_code=$(curl -s -o /tmp/docs.json -w "%{http_code}" "$SUPABASE_URL/rest/v1/documents?space_id=eq.00000000-0000-0000-0000-000000000000&select=id&limit=1" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $token")
echo "   documents HTTP $docs_code (404 table missing, 200/[] OK)"

echo "OK — Chat & Spaces API reachable for signed-in user."
