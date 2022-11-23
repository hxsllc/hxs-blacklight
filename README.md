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
2) Build Image `ENV RAILS_MASTER_KEY=[MASTER_KEY] docker buildx build --platform linux/x86_64 -t hxs-blacklight-app --file .docker/rails.prod.Dockerfile --secret id=master_key,env=RAILS_MASTER_KEY --build-arg RAILS_PORT=80 .`
2) Tag Image `docker tag hxs-blacklight-app:latest 214159447841.dkr.ecr.us-east-2.amazonaws.com/hxs-blacklight-app:latest`
3) Push Image `docker push 214159447841.dkr.ecr.us-east-2.amazonaws.com/hxs-blacklight-app:latest`

### Build & Push Solr Image

1) Login to AWS ECR `aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 214159447841.dkr.ecr.us-east-2.amazonaws.com`
2) Build Image `docker buildx build --platform linux/x86_64 -t hxs-blacklight-solr --file .docker/solr.prod.Dockerfile .`
3) Tag Image `docker tag hxs-blacklight-solr:latest 214159447841.dkr.ecr.us-east-2.amazonaws.com/hxs-blacklight-solr:latest`
4) Push Image `docker push 214159447841.dkr.ecr.us-east-2.amazonaws.com/hxs-blacklight-solr:latest`

### Tips & Tricks

- Force a deployment: `hxs-blacklight % aws ecs update-service --force-new-deployment --region us-east-2 --cluster hxs-blacklight-staging --service hxs-blacklight`

### Troubleshooting

#### - Receive the following error when trying to login to ECR:

`Error saving credentials: error storing credentials - err: exit status 1, out: 'Post "http://ipc/registry/credstore-updated": dial unix backend.sock: connect: no such file or directory'`

Make sure that the docker server is running.

### Log Into Solr

1) Log into [**AWS**](https://aws.amazon.com)
2) Navigate to the [**ECS Console**]( https://us-east-2.console.aws.amazon.com/ecs)
3) Select **Clusters**
4) Select **hxs-blacklight-staging**
5) Under **Services** select **hxs-blacklight**
6) Click on the **Configuration and Tasks**
7) Under the **Tasks** Panel, select the top most task
8) Under the **Configuration** look for the public IP
9) Copy the public IP and past it into the browser
10) Change the port to **8983**
