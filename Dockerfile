# syntax=docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.3.5
ARG RAILS_ENV=production # Default to production, can be overridden
ARG BUNDLE_WITHOUT="development:test" # Default bundle without for production

# --- Base Stage ---
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base
WORKDIR /rails
# Install base packages + netcat + build dependencies needed later
# Moved comments to separate lines for clarity and to avoid parsing errors
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    # Runtime Dependencies:
    curl \
    libjemalloc2 \
    libvips \
    postgresql-client \
    # For entrypoint DB check:
    netcat-openbsd \
    # Build-time Dependencies (kept in base for multi-stage access):
    build-essential \
    git \
    libpq-dev \
    pkg-config \
    # Link commands and cleanup
    && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives
ENV LANG C.UTF-8

# --- Build Stage (Common dependencies) ---
FROM base AS build
# Set bundle config based on build args
ENV BUNDLE_WITHOUT=${BUNDLE_WITHOUT} \
    BUNDLE_DEPLOYMENT=${RAILS_ENV:-production} \
    BUNDLE_PATH="/usr/local/bundle"

# Copy gem files and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application code AFTER bundle install for better caching
COPY . .

# Precompile bootsnap (if applicable for the env)
RUN bundle exec bootsnap precompile app/ lib/

# --- Development Stage ---
FROM build AS development
ENV RAILS_ENV=development
WORKDIR /rails
EXPOSE 3000
COPY bin/docker-entrypoint /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint
ENTRYPOINT ["docker-entrypoint"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

# --- Production Stage (Final slim stage) ---
FROM base AS production
ENV RAILS_ENV="production" \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_PATH="/usr/local/bundle"

# Copy only necessary artifacts from build stage
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp /usr/local/bundle
USER 1000:1000

# Copy and set entrypoint
COPY bin/docker-entrypoint /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint
ENTRYPOINT ["docker-entrypoint"]

EXPOSE 3000
CMD ["bundle", "exec", "rails", "server"]