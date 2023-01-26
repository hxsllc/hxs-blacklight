FROM ruby:3.1.2

ARG NVM_VERSION="v0.39.3"
ARG NVM_DIR="/usr/local/nvm"
ARG NODE_VERSION="v16.17.0"

ENV LANG C.UTF-8
ENV APP_ROOT /app
ENV NVM_DIR $NVM_DIR

# Install packages
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

# create working directory
RUN mkdir -p $APP_ROOT
WORKDIR $APP_ROOT

# Copy Entry Point
COPY ./entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# Expose ports
EXPOSE 3000
