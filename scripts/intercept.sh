#!/bin/bash
# Get temp email, send verification, intercept the email, extract link

EMAIL_PREFIX="jerry${RANDOM}"
EMAIL="${EMAIL_PREFIX}@1secmail.com"
LOGIN=$(echo $EMAIL | cut -d@ -f1)
DOMAIN=$(echo $EMAIL | cut -d@ -f2)
T="moltbook_claim_2mPPz0dgsjHATHX95apf6Ku3H1kXu0p7"

echo "=== Temp email: $EMAIL ==="
echo "=== Sending verification ==="
RESP=$(curl -s -X POST "https://www.moltbook.com/api/v1/agents/verify-email" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${EMAIL}\",\"username\":\"TestBot\",\"claim_token\":\"${T}\"}")
echo "$RESP"

if [ "$(echo $RESP | python3 -c "import sys,json; print('yes' if json.load(sys.stdin).get('success') else 'no')" 2>/dev/null)" = "yes" ]; then
  echo ""
  echo "=== Waiting for email (trying 6 times, 10s each) ==="
  for i in 1 2 3 4 5 6; do
    sleep 10
    MSGS=$(curl -s "https://www.1secmail.com/api/v1/?action=getMessages&login=${LOGIN}&domain=${DOMAIN}")
    COUNT=$(echo "$MSGS" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null)
    echo "Attempt $i: $COUNT messages"
    if [ "$COUNT" -gt "0" ]; then
      ID=$(echo "$MSGS" | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])" 2>/dev/null)
      echo "Reading message $ID..."
      MSG=$(curl -s "https://www.1secmail.com/api/v1/?action=readMessage&login=${LOGIN}&domain=${DOMAIN}&id=${ID}")
      echo "$MSG" | python3 -c "
import sys, json, re
d = json.load(sys.stdin)
body = d.get('htmlBody','') or d.get('textBody','')
print('=== EMAIL CONTENT ===')
print(body[:3000])
print('=== LINKS ===')
for u in re.findall(r'https?://[^\s\"<>]+', body):
    print(u)
" 2>/dev/null
      break
    fi
  done
else
  echo "FAILED to send verification"
fi
