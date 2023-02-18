# syntax = docker/dockerfile:experimental
# Build app
FROM public.ecr.aws/docker/library/node:16-alpine as builder
# Cache APK
RUN --mount=type=cache,target=/var/cache/apk ln -vs /var/cache/apk /etc/apk/cache && \
    apk add --no-cache libc6-compat
WORKDIR /build
COPY yarn.lock package.json ./
# Cache yarn
RUN --mount=type=cache,target=/root/.yarn YARN_CACHE_FOLDER=/root/.yarn yarn install --frozen-lockfile
COPY . .
RUN yarn build
RUN npm prune --production

FROM public.ecr.aws/docker/library/node:16-alpine AS runner
WORKDIR /app

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 app
USER app

# Copy needed files only
COPY --from=builder --chown=app:nodejs /build/.env ./.env
COPY --from=builder --chown=app:nodejs /build/public ./public
COPY --from=builder --chown=app:nodejs /build/.next/static ./.next/static
COPY --from=builder --chown=app:nodejs /build/.next/standalone ./

CMD node server.js