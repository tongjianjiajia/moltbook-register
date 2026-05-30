import requests, re, json, sys

# This runs from US GitHub runner - no geo-block

print('=== 1. Fetching claim page ===')
r = requests.get('https://www.moltbook.com/claim/moltbook_claim_2mPPz0dgsjHATHX95apf6Ku3H1kXu0p7')
html = r.text

# Find build ID
bd = re.search(r'buildId["\:\s]+([a-zA-Z0-9]+)', html)
build_id = bd.group(1) if bd else 'unknown'
print('Build ID:', build_id)

# Try Next.js data endpoint
print('\n=== 2. Next.js data ===')
data = requests.get('https://www.moltbook.com/_next/data/' + build_id + '/claim/moltbook_claim_2mPPz0dgsjHATHX95apf6Ku3H1kXu0p7.json')
print('Status:', data.status_code)
if data.status_code == 200:
    print(json.dumps(data.json(), indent=2, ensure_ascii=False)[:3000])

# Try auth endpoints
print('\n=== 3. Auth endpoints ===')
for ep in ['/api/v1/auth/me']:
    r = requests.get('https://www.moltbook.com' + ep)
    print(ep + ': ' + str(r.status_code))
    try:
        print(json.dumps(r.json(), indent=2, ensure_ascii=False)[:500])
    except:
        print(r.text[:200])

# Search for supabase URLs in JS
print('\n=== 4. Looking for API endpoints in JS ===')
js_files = set(re.findall(r'/_next/static/chunks/([a-zA-Z0-9._-]+\.js)', html))

# Check largest JS files for auth-related code
import heapq
js_with_sizes = []
for js in js_files:
    url = 'https://www.moltbook.com' + '/_next/static/chunks/' + js
    try:
        resp = requests.get(url, timeout=10)
        js_with_sizes.append((len(resp.text), js, resp.text))
    except:
        pass

with_https = set()
for _, js_name, content in heapq.nlargest(5, js_with_sizes):
    # Extract all API endpoints
    for pat in [r'\"/(api/v1/[a-zA-Z0-9_/-]+)\"', r"'/(api/v1/[a-zA-Z0-9_/-]+)'"]:
        for m in re.findall(pat, content):
            with_https.add('/' + m)
    # Find any https URLs
    for m in re.findall(r'https?://[a-zA-Z0-9._/-]+', content):
        with_https.add(m)

print('Found ' + str(len(with_https)) + ' unique URLs/endpoints:')
for ep in sorted(with_https):
    print('  ' + ep)
