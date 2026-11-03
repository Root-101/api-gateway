#STEP 1: BUILD
#pinned base + shallow clone of the exact flutter tag: reproducible and much faster than a full clone
FROM debian:bookworm-slim AS build-env

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl git unzip xz-utils ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG FLUTTER_VERSION=3.47.9
ARG FLUTTER_SDK_LOCATION=/usr/local/flutter

RUN git clone --depth 1 --branch $FLUTTER_VERSION https://github.com/flutter/flutter.git $FLUTTER_SDK_LOCATION
ENV PATH="$FLUTTER_SDK_LOCATION/bin:$FLUTTER_SDK_LOCATION/bin/cache/dart-sdk/bin:${PATH}"

RUN flutter config --no-analytics && flutter precache --web

WORKDIR /app
#dependencies first, so the pub get layer is cached while only code changes
#glob: pubspec.lock is git-ignored, so it may be missing in a clean clone
COPY pubspec.* ./
RUN flutter pub get
COPY . .
RUN flutter build web --release

#STEP 2: DEPLOY
FROM nginx:1.28-alpine

COPY --from=build-env /app/build/web /usr/share/nginx/html
#security headers + cache policy (replaces the default server config)
COPY nginx.conf /etc/nginx/conf.d/default.conf
#the nginx image runs /docker-entrypoint.d/*.sh on start: env.js is generated from the container env vars
COPY docker/40-env-js.sh /docker-entrypoint.d/40-env-js.sh
RUN chmod +x /docker-entrypoint.d/40-env-js.sh

#build args are kept only as defaults, so existing `docker compose` files with `args:` keep working;
#prefer runtime `environment:` (same names) to reuse one image across environments
ARG GATEWAY_SERVICE_URL
ARG ADMIN_PATH
#optional: minutes of inactivity before logout, 0 = disabled
ARG SESSION_TIMEOUT_MINUTES=0
ENV GATEWAY_SERVICE_URL=${GATEWAY_SERVICE_URL} \
    ADMIN_PATH=${ADMIN_PATH} \
    SESSION_TIMEOUT_MINUTES=${SESSION_TIMEOUT_MINUTES}

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
