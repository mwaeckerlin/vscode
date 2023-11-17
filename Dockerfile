FROM mwaeckerlin/dockindock AS docker

FROM mwaeckerlin/nodejs-build AS build
ENV BUILD_PKGS "alpine-sdk bash libstdc++ libc6-compat npm python3 krb5-pkinit krb5-dev krb5 shadow"
ENV HOME /code
ENV FORCE_NODE_VERSION false
COPY --from=docker / /
USER root
RUN $PKG_INSTALL $BUILD_PKGS
RUN npm install -g code-server --unsafe-perm
RUN usermod -d ${HOME} ${RUN_USER}
RUN ${ALLOW_USER} ${HOME}
RUN rm -rf /app /home
COPY .profile ${HOME}/
ENV RUN_PKGS "git openssh rootlesskit"
RUN $PKG_INSTALL $RUN_PKGS

FROM mwaeckerlin/dockindock
ENV CONTAINERNAME "vscode"
ENV SHELL "/bin/bash"
ENV HOME "/code"
ENV XDG_RUNTIME_DIR "/docker"
ENV PATH "${XDG_RUNTIME_DIR}/bin:$PATH"
ENV DOCKER_HOST "unix://${XDG_RUNTIME_DIR}/docker.sock"
COPY --from=build / /
CMD HOME=${XDG_RUNTIME_DIR} ${XDG_RUNTIME_DIR}/bin/dockerd-rootless.sh & \
    /usr/local/bin/code-server --bind-addr 0.0.0.0:${PORT:-8080} \
                               --config ${HOME}/.config/config.yaml \
                               --user-data-dir ${HOME}/.config
WORKDIR ${HOME}
VOLUME ${HOME}
EXPOSE 8080
