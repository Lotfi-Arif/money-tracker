# Base stage with pnpm
FROM node:20-alpine AS base

# Enable pnpm
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

WORKDIR /usr/src/app

# Copy package files and lockfile
COPY pnpm-lock.yaml package.json ./
COPY prisma ./prisma/

# Development stage
FROM base AS development
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile
COPY . .
RUN pnpm prisma:dev:generate
CMD ["pnpm", "dev"]

# Production build stage
FROM base AS build
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile
COPY . .
RUN pnpm prisma:prod:generate
RUN pnpm build

# Production stage
FROM base AS production
# Only install production dependencies
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile
COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/prisma ./prisma
RUN pnpm prisma:prod:generate
CMD ["pnpm", "prod"]
