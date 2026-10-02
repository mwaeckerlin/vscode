# Tests

Register of all tests, sorted by the [FEATURES.md](FEATURES.md) number each test covers. `npm test` runs everything; the guard `tests/docs-contract.sh` fails when a feature has no test entry here or a test carries a skip marker.

## E2E (`tests/run-e2e.sh`, client `tests/e2e/test_login.py`)

- **F1** plain_login_page, hashed_login_page — code-server answers on port 8080.
- **F2** plain_editor_needs_login, plain_wrong_password_refused, plain_right_password_logs_in, and the same three for `hashed` — the editor needs the login, a wrong password gets no session, the right one does, with `PASSWORD` and with `HASHED_PASSWORD`.
- **F3** refuses_to_start_without_password — without a password the container ends with its message (regression: the repository carried a `.env` with a published password that every default installation used).
- **F4** docker_daemon_inside — `docker info` answers inside the running container.
- **F5** plain_login_page — the editor writes its configuration into `/code` and starts, which it cannot without write access.

## Workflow contract

- **F6** `tests/workflow-contract.sh` of `mwaeckerlin/scratch` — the reusable workflow selects exactly the images a repository publishes; this repository calls it from `.github/workflows/docker.yml`.
