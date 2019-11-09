FROM ruby:2.6.4-alpine3.10

# If true then development gems and libraries are included
# in the container.
ARG INCLUDE_DEV_ITEMS=true

# Environment and port when running the container.  Override
# for other envrionments other then development.
ENV RAILS_ENV=development
ENV PORT=3000

# Working directory.
RUN mkdir /app
WORKDIR /app

# build-base: Build some gems.
# postgressql-dev: Connect to Postgres DB.
# nodejs: Used by Rails.
# tzdata: Used by Rails.
# yarn: Used by Rails to manage node packages.
# bash, git, wget, chromium: Required by Sorbet and Rails Sorbet
# glibc: Required by Sorbet but there is no Alpine package so it must be installed manullay.
RUN apk update && \
    apk add --no-cache "build-base" \
                       "postgresql-dev" \
                       "nodejs" \
                       "tzdata" \
                       "yarn" \
                       "bash" \
                       "git" \
                       "wget" \
                       "chromium" && \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.30-r0/glibc-2.30-r0.apk && \
    apk add --no-cache "glibc-2.30-r0.apk"

# Install the gems.
COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v 2.0.2
RUN if [ "$INCLUDE_DEV_ITEMS" = "true" ] ; then \
    bundle install ; \
    else \
    bundle install --without development test ; \
    fi

# Yarn packages.
COPY package.json yarn.lock .yarnrc ./
RUN if [ "${INCLUDE_DEV_ITEMS}" = "true" ] ; then \
    yarn install --check-files --frozen-lockfile ; \
    else \
    yarn install --check-files --frozen-lockfile --no-cache --production ; \
    fi

# Add the code.
COPY . .

# Expose the port.
EXPOSE $PORT

# Rubymine does not respect the working directory
# so can't find the entrypoint if you don't put
# the full path of the entry point.
RUN chmod +x docker-entrypoint.sh
ENTRYPOINT ["/app/docker-entrypoint.sh"]
