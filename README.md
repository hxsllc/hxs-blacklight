# README

## Docker Development Environment

### Dependencies
- [Docker](https://docs.docker.com/desktop/)
- [`docker-compose`](https://docs.docker.com/compose/install/)

### Setup
1) Clone this repo `gh repo clone jefawks3/hxs-blacklight`
2) Open the Terminal and CD to repo `cd hxs-blacklight`
3) Run `docker-compose build`
4) Run `docker-compose run --rm app bundle install -j8`
5) Run `docker-compose run --rm app rake db:migrate`
6) Run `docker-compose up`
7) Open http://localhost:3000 in the browser

If you want to add test MARC records run `docker-compose run app rake solr:marc:index_test_data`

### Changes

- Code - *No Action* - Code changes should be detected by Rails
- Migrations - Run `docker-compose run --rm app rake db:migrate`
- Gemfile - Rerun `docker-compose run --rm app bundle install` and restart `app` container

### Links/URLs
- Web - http://localhost:3000
- Solr - http://localhost:8983/solr
- MySql -  http://localhost:3306

## Deploy to Staging Environment

Notes:
1) You only need to rebuild any images that have changes.
2) ECS is configured to run on Linux x86_64 architecture; make sure to specify the platform when building.

### Build & Push App Image

1) Login to AWS ECR `aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 214159447841.dkr.ecr.us-east-2.amazonaws.com`
2) Build Image `ENV RAILS_MASTER_KEY=[MASTER_KEY] docker buildx build --platform linux/x86_64 -t hxs-blacklight-app --file .docker/rails.prod.Dockerfile --secret id=RAILS_MASTER_KEY --build-arg RAILS_PORT=80 .`
2) Tag Image `docker tag hxs-blacklight-app:latest 214159447841.dkr.ecr.us-east-2.amazonaws.com/hxs-blacklight-app:latest`
3) Push Image `docker push 214159447841.dkr.ecr.us-east-2.amazonaws.com/hxs-blacklight-app:latest`

### Build & Push Solr Image

1) Login to AWS ECR `aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 214159447841.dkr.ecr.us-east-2.amazonaws.com`
2) Build Image `docker buildx build --platform linux/x86_64 -t hxs-blacklight-solr --file .docker/solr.prod.Dockerfile .`
3) Tag Image `docker tag hxs-blacklight-solr:latest 214159447841.dkr.ecr.us-east-2.amazonaws.com/hxs-blacklight-solr:latest`
4) Push Image `docker push 214159447841.dkr.ecr.us-east-2.amazonaws.com/hxs-blacklight-solr:latest`


