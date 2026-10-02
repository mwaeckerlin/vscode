# Features

Numbered register of every feature; a number is never reused. Every feature is covered by tests listed in [TESTS.md](TESTS.md); the guard `tests/docs-contract.sh` fails when a feature has no test.

- **F1 — Visual Studio Code in the browser.** code-server serves the editor on port 8080 (`PORT`), with the user home and configuration in the volume `/code`.
- **F2 — Password login.** The editor is reachable only after a login with `PASSWORD`, or with the argon2 hash in `HASHED_PASSWORD`; a wrong password gets no session.
- **F3 — No default password.** Without `PASSWORD` and without `HASHED_PASSWORD` the container refuses to start and says why, so no installation runs with a known password.
- **F4 — Docker inside.** A rootless docker daemon runs inside the container (started with `--privileged`), so projects in the editor build and run containers without access to the host's docker.
- **F5 — Write access to the volume.** The compose service `fix-access` (`mwaeckerlin/allow-write-access`) gives the unprivileged user write access to `/code`.
- **F6 — Published for amd64 and arm64.** Every push builds the image natively for both architectures and publishes it under one tag on Docker Hub, with the reusable workflow of `mwaeckerlin/scratch`.
