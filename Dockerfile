FROM mwaeckerlin/dockindock as docker

FROM mwaeckerlin/nodejs-build AS build
ENV HOME /data
ENV FORCE_NODE_VERSION 16
COPY --from=docker / /
RUN $PKG_INSTALL curl docker openssh-client shadow
RUN rmdir /usr/local/bin
RUN mv /home/${RUN_USER}/bin /usr/local/bin
RUN npm install -g code-server --unsafe-perm
RUN mv /home/${RUN_USER} ${HOME}
RUN usermod -d ${HOME} ${RUN_USER}
RUN mkdir -p "${HOME}/.docker/run"
RUN ${ALLOW_USER} ${HOME}
RUN rm -rf /app

FROM mwaeckerlin/scratch
ENV CONTAINERNAME "vscode"
ENV PASSWORD "change-me"
ENV SHELL "/bin/sh"
ENV HOME "/data"
ENV PATH "usr/local/bin:${PATH}"
ENV XDG_RUNTIME_DIR "${HOME}/.docker/run"
ENV DOCKER_HOST "unix://${HOME}/.docker/run/docker.sock"
COPY --from=build / /
WORKDIR ${HOME}
USER ${RUN_USER}
EXPOSE 8080
CMD [ "/bin/sh", "-c", "/usr/local/bin/dockerd-rootless.sh & /usr/local/bin/code-server --bind-addr 0.0.0.0:${PORT:-8080} --config /data/.config/config.yaml --user-data-dir /data/.config" ]
VOLUME ${HOME}
