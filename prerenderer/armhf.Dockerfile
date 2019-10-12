FROM balenalib/armv7hf-alpine-node:3.10

LABEL maintainer="Sandro Jäckel <sandro.jaeckel@gmail.com>" \
  org.opencontainers.image.created=$BUILD_DATE \
  org.opencontainers.image.authors="Sandro Jäckel <sandro.jaeckel@gmail.com>" \
  org.opencontainers.image.url="https://github.com/SuperSandro2000/docker-images/tree/master/prerender" \
  org.opencontainers.image.documentation="https://github.com/prerender/prerender" \
  org.opencontainers.image.source="https://github.com/SuperSandro2000/docker-images" \
  org.opencontainers.image.version=$VERSION \
  org.opencontainers.image.revision=$REVISION \
  org.opencontainers.image.vendor="SuperSandro2000" \
  org.opencontainers.image.licenses="MIT" \
  org.opencontainers.image.title="Prerenderer" \
  org.opencontainers.image.description="Node server that uses Headless Chrome to render a javascript-rendered page as HTML. To be used in conjunction with prerender middleware."

RUN [ "cross-build-start" ]

RUN addgroup -S prerenderer && adduser -g prerenderer -S prerenderer

COPY [ "files/entrypoint.sh", "/usr/local/bin/" ]

RUN apk add --no-cache --no-progress chromium git \
  && git clone https://github.com/prerender/prerender.git . \
  && apk del git

WORKDIR /app

RUN npm install

COPY [ "files/server.js", "/app/" ]

RUN [ "cross-build-end" ]

EXPOSE 3000
ENTRYPOINT [ "entrypoint.sh" ]
CMD ["npm", "start", "server"]
