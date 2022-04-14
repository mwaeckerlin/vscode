FROM mwaeckerlin/dockindock AS docker

FROM mwaeckerlin/nodejs-build AS build
ENV HOME /data
ENV FORCE_NODE_VERSION 16
COPY --from=docker / /
RUN $PKG_INSTALL curl openssh-client shadow
RUN npm install -g code-server --unsafe-perm
RUN usermod -d ${HOME} ${RUN_USER}
RUN ${ALLOW_USER} ${HOME}
RUN rm -rf /app /home

FROM mwaeckerlin/dockindock
ENV CONTAINERNAME "vscode"
ENV PASSWORD "change-me"
ENV SHELL "/bin/sh"
ENV HOME "/data"
COPY --from=build / /
CMD HOME=${XDG_RUNTIME_DIR} ${XDG_RUNTIME_DIR}/bin/dockerd-rootless.sh & \
    /usr/local/bin/code-server --bind-addr 0.0.0.0:${PORT:-8080} \
                               --config ${HOME}/.config/config.yaml \
                               --user-data-dir ${HOME}/.config
WORKDIR ${HOME}
VOLUME ${HOME}
EXPOSE 8080
