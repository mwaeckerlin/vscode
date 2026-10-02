"""E2E tests for mwaeckerlin/vscode, run inside the compose network.

Logs in to code-server with the right and a wrong password, for the plain
and the hashed variant. Only the Python standard library is used.
"""
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

results = []


def check(name, condition, detail=''):
    results.append(condition)
    print(f"  {'PASS' if condition else 'FAIL'}  {name}" + ('' if condition else f': {detail}'))


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


opener = urllib.request.build_opener(NoRedirect)


def call(url, password=None):
    data = urllib.parse.urlencode({'password': password}).encode() if password is not None else None
    try:
        with opener.open(urllib.request.Request(url, data=data), timeout=20) as response:
            return response.status, response.headers, response.read().decode(errors='replace')
    except urllib.error.HTTPError as error:
        return error.code, error.headers, error.read().decode(errors='replace')


def wait_for(base):
    for _ in range(180):
        try:
            if call(base + '/login')[0] == 200:
                return
        except OSError:
            pass
        time.sleep(1)
    raise SystemExit(f'{base} did not answer')


for name, base, password in (('plain', 'http://vscode:8080', 'e2e-password'),
                             ('hashed', 'http://vscode-hashed:8080', 'e2e-hashed')):
    wait_for(base)
    status, _, body = call(base + '/login')
    check(f'{name}_login_page', status == 200 and 'code-server' in body.lower(), (status, body[:200]))
    status, headers, _ = call(base + '/', None)
    check(f'{name}_editor_needs_login', status in (302, 303) and 'login' in (headers.get('Location') or ''),
          (status, headers.get('Location')))
    status, headers, body = call(base + '/login', 'wrong-password')
    check(f'{name}_wrong_password_refused', not (headers.get('Set-Cookie') or '').startswith('code-server-session'),
          (status, headers.get('Set-Cookie')))
    status, headers, _ = call(base + '/login', password)
    check(f'{name}_right_password_logs_in', status in (302, 303) and 'code-server-session' in (headers.get('Set-Cookie') or ''),
          (status, headers.get('Set-Cookie')))

print(f"\n==> E2E results: {results.count(True)} passed, {results.count(False)} failed")
sys.exit(0 if all(results) else 1)
