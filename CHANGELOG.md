# Changelog

- 2026-10-02 **1.0.1**
    - Security: there is no default password any more; the repository carried one in a `.env` file, and every installation that kept the defaults used it. The container now refuses to start without `PASSWORD` or `HASHED_PASSWORD`; whoever used the old default must set a new password
    - The volume gets write access through the headless `mwaeckerlin/allow-write-access`
    - The image is published for amd64 and arm64 under one tag, built and published automatically on every change and every week

- 2026-05-22 **1.0.0**
    - Visual Studio Code in the browser (code-server) with password login, the user home in a volume, and a rootless docker daemon inside the container
