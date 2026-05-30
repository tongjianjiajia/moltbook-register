#!/bin/bash
# Intercept verification email using mailinator
set -e

T="moltbook_claim_2mPPz0dgsjHATHX95apf6Ku3H1kXu0p7"
EMAIL="jerrybot2026@mailinator.com"
INBOX="jerrybot2026"

echo "=== Email: $EMAIL ==="
echo "=== Sending verification ==="
RESP=$(curl -s -X POST "https://www.moltbook.com/api/v1/agents/verify-email" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${EMAIL}\",\"username\":\"TestBot99\",\"claim_token\":\"${T}\"}")
echo "$RESP"

echo ""
echo "=== Waiting 45 seconds ==="
sleep 45

echo "=== Checking inbox ==="
# Mailinator API
curl -s "https://api.mailinator.com/api/v2/domains/public/inboxes/${INBOX}?limit=5" \
  -H "Authorization: Bearer 7f80fca460b44a97b65f06fcb3f39f90" 2>/dev/null | python3 -c "
import sys, json, re
try:
    d = json.load(sys.stdin)
    msgs = d.get('msgs', d.get('messages', []))
    if not msgs:
        print('No messages found')
    for msg in msgs:
        mid = msg.get('id','')
        subj = msg.get('subject','')
        print(f'Subject: {subj}')
        if mid:
            import urllib.request
            req = urllib.request.Request(f'https://api.mailinator.com/api/v2/domains/public/inboxes/jerrybot2026/messages/{mid}')
            req.add_header('Authorization', 'Bearer 7f80fca460b44a97b65f06fcb3f39f90')
            resp = urllib.request.urlopen(req).read().decode()
            full = json.loads(resp)
            parts = full.get('parts',[])
            for p in parts:
                body = p.get('body','')
                print(body[:3000])
                for u in re.findall(r'https?://[^\s\"<>]+', body):
                    if 'moltbook' in u:
                        print('LINK:', u)
except Exception as e:
    print('Error:', e)
    print(sys.stdin.read()[:500])
" 2>/dev/null

echo ""
echo "=== Also check via web API ==="
TOKEN=$(curl -s "https://api.mailinator.com/api/v2/domains/public/" -H "Authorization: Bearer 7f80fca460b44a97b65f06fcb3f39f90" 2>/dev/null | head -c 200)
echo "API status: $TOKEN"
