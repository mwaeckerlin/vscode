FROM mwaeckerlin/dockindock AS docker

FROM mwaeckerlin/nodejs-build AS build
ENV BUILD_PKGS="alpine-sdk bash curl libstdc++ libc6-compat npm python3 krb5-pkinit krb5-dev krb5 shadow"
ENV HOME=/code
ENV FORCE_NODE_VERSION=false
# code-server's postinstall runs npm again inside the install; on a slow link
# the default read timeout broke it off (ETIMEDOUT, measured 2026-10-02), so
# every npm of this stage waits longer and repeats
ENV NPM_CONFIG_FETCH_TIMEOUT=1800000 \
    NPM_CONFIG_FETCH_RETRIES=10 \
    NPM_CONFIG_FETCH_RETRY_MINTIMEOUT=10000
# node-gyp downloads the Node.js headers once, without a retry, and that
# download timed out the same way (measured 2026-10-02); the headers of the
# Node.js that is installed are fetched below with retries and handed to
# node-gyp as a file. Alpine's own nodejs-dev headers carry the link-time
# optimisation of Alpine's Node.js build, and the native modules of
# code-server do not link with it.
ENV NPM_CONFIG_TARBALL=/tmp/node-headers.tar.gz
# @vscode/spdlog builds with link-time optimisation, and with the gcc and the
# fortified C headers of current Alpine its link stops at «inlining failed in
# call to 'always_inline' 'snprintf'» (measured 2026-10-02); the native
# modules are built without link-time optimisation, the fortified headers
# stay in force
ENV CFLAGS="-fno-lto" \
    CXXFLAGS="-fno-lto" \
    LDFLAGS="-fno-lto"
COPY --from=docker / /
USER root
RUN $PKG_INSTALL $BUILD_PKGS
RUN curl -fL --retry 10 --retry-all-errors --retry-delay 10 --connect-timeout 30 \
        -o "${NPM_CONFIG_TARBALL}" "https://nodejs.org/download/release/$(node -v)/node-$(node -v)-headers.tar.gz"
# code-server's own install runs a second npm that downloads several hundred
# packages; one read that times out on a slow link aborts all of it, so the
# install is repeated up to three times and the last failure stops the build
RUN for attempt in 1 2 3; do \
        npm install -g code-server && break; \
        echo "code-server install attempt ${attempt} failed" >&2; \
        if [ "${attempt}" = 3 ]; then exit 1; fi; \
    done \
    && test -x /usr/local/bin/code-server
RUN usermod -d ${HOME} ${RUN_USER}
RUN ${ALLOW_USER} ${HOME}
RUN rm -rf /app /home
COPY .profile ${HOME}/
ENV RUN_PKGS="git openssh rootlesskit"
RUN $PKG_INSTALL $RUN_PKGS

FROM mwaeckerlin/dockindock
ENV CONTAINERNAME="vscode"
ENV SHELL="/bin/bash"
ENV HOME="/code"
ENV XDG_RUNTIME_DIR="/docker"
ENV PATH="${XDG_RUNTIME_DIR}/bin:$PATH"
ENV DOCKER_HOST="unix://${XDG_RUNTIME_DIR}/docker.sock"
COPY --from=build / /
# a shell command line on purpose: it refuses to start without a password,
# starts the rootless docker daemon in the background and code-server in
# front; the image has a shell anyway (rootless docker needs one)
CMD ["/bin/sh", "-c", "if [ -z \"${PASSWORD}${HASHED_PASSWORD}\" ]; then echo 'vscode: set PASSWORD or HASHED_PASSWORD, there is no default password' >&2; exit 1; fi; HOME=${XDG_RUNTIME_DIR} ${XDG_RUNTIME_DIR}/bin/dockerd-rootless.sh & exec /usr/local/bin/code-server --bind-addr 0.0.0.0:${PORT:-8080} --auth password --config ${HOME}/.config/config.yaml --user-data-dir ${HOME}/.config"]
WORKDIR ${HOME}
VOLUME ${HOME}
EXPOSE 8080
