import requests, re, json, heapq, sys

# Search for all auth/verify related endpoints in Moltbook JS
r = requests.get('https://www.moltbook.com/claim/moltbook_claim_2mPPz0dgsjHATHX95apf6Ku3H1kXu0p7')
html = r.text
js_files = set(re.findall(r'/_next/static/chunks/([a-zA-Z0-9._-]+\.js)', html))

print('=== Deep scanning JS for auth/verify endpoints ===')

all_endpoints = set()
all_verify = []

for js_name in js_files:
    url = 'https://www.moltbook.com' + '/_next/static/chunks/' + js_name
    try:
        resp = requests.get(url, timeout=10)
        content = resp.text
        
        # Method+path patterns
        for m in re.finditer(r'(GET|POST|PUT|PATCH|DELETE)\s+["\']([^"\']+)\s*["\']', content):
            path = m.group(2)
            if '/api/' in path or '/auth/' in path:
                all_endpoints.add(m.group(1) + ' ' + path)
        
        # String literal paths
        for pat in [r'["\'](/api/v1/[a-zA-Z0-9_/:-]+)["\']', r'["\'](/auth/[a-zA-Z0-9_/:-]+)["\']']:
            for m in re.findall(pat, content):
                all_endpoints.add(m)
        
        # Look for verify/auth/signup/register mentions
        for keyword in ['verify', 'auth', 'signup', 'register', 'login', 'signin', 'email', 'token', 'callback', 'oauth', 'confirm']:
            for m in re.finditer(f'["\\x27](/[^"\\x27]*{keyword}[^"\\x27]*)["\\x27]', content, re.IGNORECASE):
                all_verify.append(m.group(1))
                
    except Exception as e:
        pass

print(f'\nAll API endpoints ({len(all_endpoints)}):')
for ep in sorted(all_endpoints):
    print(f'  {ep}')

print(f'\nAll auth/verify related paths ({len(all_verify)}):')
for p in sorted(set(all_verify)):
    print(f'  {p}')
