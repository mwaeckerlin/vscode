#!/usr/bin/env bash
# E2E tests for mwaeckerlin/vscode: no start without a password, login with a
# plain and with a hashed password, the docker daemon inside the container.
# Usage: bash tests/run-e2e.sh
set -uo pipefail

cd "$(dirname "$0")/.."
COMPOSE="tests/e2e/docker-compose.yml"
IMAGE="mwaeckerlin/vscode"

cleanup() { docker compose -f "$COMPOSE" --profile tester down -v --remove-orphans > /dev/null 2>&1 || true; }
trap cleanup EXIT

EXIT=0
_pass() { echo "  PASS  $1"; }
_fail() { echo "  FAIL  $1: $2"; EXIT=1; }

echo "==> E2E: no default password"
OUT=$(timeout 60 docker run --rm --pull=never "$IMAGE" 2>&1)
RC=$?
if [[ ${RC} -ne 0 && "${OUT}" == *"set PASSWORD or HASHED_PASSWORD"* ]]; then
    _pass "refuses_to_start_without_password"
else
    _fail "refuses_to_start_without_password" "rc=${RC}: ${OUT: -300}"
fi

# the argon2 hash of «e2e-hashed», made with the argon2 module code-server brings
E2E_HASH=$(docker run --rm --pull=never --entrypoint node -w /usr/local/lib/node_modules/code-server "$IMAGE" \
    -e "require('argon2').hash('e2e-hashed').then(h => console.log(h))" 2>&1)
export E2E_HASH
if [[ "${E2E_HASH}" != '$argon2'* ]]; then
    _fail "hash_for_the_test" "${E2E_HASH}"
fi

cleanup
docker compose -f "$COMPOSE" up -d vscode vscode-hashed > /dev/null 2>&1
docker compose -f "$COMPOSE" run --rm tester || EXIT=1

echo "==> E2E: docker inside"
DOCKER_OK=0
for _ in $(seq 60); do
    if docker compose -f "$COMPOSE" exec -T vscode docker info > /dev/null 2>&1; then DOCKER_OK=1; break; fi
    sleep 2
done
if [[ ${DOCKER_OK} -eq 1 ]]; then _pass "docker_daemon_inside"; else _fail "docker_daemon_inside" "$(docker compose -f "$COMPOSE" logs vscode 2>&1 | tail -20)"; fi

if [[ ${EXIT} -ne 0 ]]; then
    echo "==> vscode logs:"
    docker compose -f "$COMPOSE" logs vscode vscode-hashed 2>&1 | tail -60
fi
exit ${EXIT}
