FROM ruby:3.1.2

ARG RAILS_ENV="production"
ARG RAKE_ENV=$RAILS_ENV
ARG NODE_ENV="production"
ARG RAILS_PORT=3000
ARG APP_ROOT="/app"

ENV RAILS_ENV=$RAILS_ENV \
    RAKE_ENV=$RAKE_ENV \
    NODE_ENV=$NODE_ENV \
    APP_ROOT=$APP_ROOT

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt-get update -qq && \
  apt-get install -y --no-install-recommends \
  build-essential \
  default-jre \
  git \
  bash \
  libxml2-dev \
  libxslt-dev \
  shared-mime-info \
  libmariadb-dev \
  nodejs \
  yarn && \
  apt-get clean && \
  rm --recursive --force /var/lib/apt/lists/* \

# Make App Working Directory
RUN mkdir $APP_ROOT
WORKDIR $APP_ROOT

# Bundle Gems
COPY ../Gemfile $APP_ROOT
COPY ../Gemfile.lock $APP_ROOT
RUN gem install bundler:2.3.7
RUN bundle config --global frozen 1
RUN bundle install --deployment --without development test

# Copy Code
COPY .. $APP_ROOT

# Remove local development directories
RUN rm -rf $APP_ROOT/tmp
RUN rm -rf $APP_ROOT/log

# Compile Assets
RUN --mount=type=secret,id=master_key cp /run/secrets/master_key $APP_ROOT/config/master.key
RUN bundle exec rake assets:precompile
RUN rm -f $APP_ROOT/config/master.key

# Expose port
EXPOSE $RAILS_PORT
