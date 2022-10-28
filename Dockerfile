FROM ruby:3.1.2

ENV LANG C.UTF-8
ENV APP_ROOT /app

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
  rm --recursive --force /var/lib/apt/lists/*

# create working directory
RUN mkdir $APP_ROOT
WORKDIR $APP_ROOT

# bundle install
COPY Gemfile* .
RUN bundle install --jobs 4 --retry 3

# create app in container
# COPY . .

COPY ./entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

EXPOSE 3000

# Start the main process
# CMD ["bundle", "exec", "rails", "server", "-p", "3000", "-b", "0.0.0.0"]
