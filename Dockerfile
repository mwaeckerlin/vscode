FROM mwaeckerlin/nodejs-build AS build
ENV HOME /data
ENV FORCE_NODE_VERSION 16
RUN $PKG_INSTALL curl docker openssh-client
RUN mkdir /config ${HOME}
RUN $ALLOW_USER /config ${HOME}
RUN rm -rf /app
RUN npm install -g code-server --unsafe-perm

FROM mwaeckerlin/scratch
COPY --from=build / /
ENV PASSWORD "change-me"
ENV SHELL "/bin/sh"
ENV HOME /data
WORKDIR ${HOME}
USER ${RUN_USER}
EXPOSE 8080
CMD /usr/local/bin/code-server --bind-addr 0.0.0.0:${PORT:-8080} --config /config/config.yaml --user-data-dir /config
VOLUME ${HOME}
VOLUME /config
