FROM ruby:3.1.2

ARG RAILS_ENV="production"
ARG RAKE_ENV=$RAILS_ENV
ARG NODE_ENV="production"
ARG RAILS_PORT=3000
ARG APP_ROOT="/app"
ARG NVM_VERSION="v0.39.3"
ARG NVM_DIR="/usr/local/nvm"
ARG NODE_VERSION="v16.17.0"
ARG YARN_NETWORK_TIMEOUT=30000

ENV RAILS_ENV=$RAILS_ENV \
    RAKE_ENV=$RAKE_ENV \
    NODE_ENV=$NODE_ENV \
    APP_ROOT=$APP_ROOT \
    NVM_DIR=$NVM_DIR

RUN apt-get update -qq && \
  apt-get install -y --no-install-recommends \
  build-essential \
  default-jre \
  git \
  curl \
  bash \
  libxml2-dev \
  libxslt-dev \
  shared-mime-info \
  libmariadb-dev && \
  apt-get clean && \
  rm --recursive --force /var/lib/apt/lists/*

# Install NVM
RUN mkdir -p $NVM_DIR
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/$NVM_VERSION/install.sh | bash
RUN /bin/bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm use --delete-prefix $NODE_VERSION"
ENV NODE_PATH $NVM_DIR/versions/node/$NODE_VERSION/bin
ENV PATH $NODE_PATH:$PATH

RUN npm -v
RUN node -v

# Install Yarn
RUN npm install --global yarn

RUN yarn -v

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

# Compile Assets
RUN --mount=type=secret,id=master_key cp /run/secrets/master_key $APP_ROOT/config/master.key
RUN bundle exec rake assets:precompile # This will build the JS files as well
RUN rm -f $APP_ROOT/config/master.key

# Cleaning up the image
RUN rm -rf $APP_ROOT/solr
RUN rm -rf $APP_ROOT/tmp
RUN rm -rf $APP_ROOT/log
RUN rm -rf $APP_ROOT/node_modules # Making the image smaller

# Expose port
EXPOSE $RAILS_PORT
