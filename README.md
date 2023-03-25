# README

This repo contains Blacklight 7.31.0 customized for Digital Scriptorium

## Blacklight Customizations

### app/assets
- /images contains custom images for the Digital Scriptorium UI
- /stylesheets contains custom CSS for for the Digital Scriptorium UI

### app/components
- ds_document_metadata_component (.rb + .html.erb)
- ds_metadata_field_component (.rb + .html.erb)
- ds_search_bar_component (.rb + .html.erb)

### app/controllers
- catalog_controller.rb contains configuration for
- -- advanced_search
- -- document title (index and show)
- -- show_tools
- -- nav_action
- -- facet_field (all metadata displayed in facet sidebar)
- -- index_field (title, author, place, date)
- -- show_field (all metadata displayed in full record view)
- -- search_field (all fields displayed in simple search drop-down + advanced search page)

### app/helpers
- application_helper.rb contains custom UI functions

### app/javascript
- /components contains custom JS functions for
- -- advanced search form
- -- pop-up alert bar
- -- copy to clipboard in full record view
- application.js contains Mirador integration

### app/models
- /concerns/solr_document.rb contains custom accessor methods used in full record view
- /presenters contains customized Ruby functions to modify default document title display

### app/views
- /advanced contains customized/overriden views for advanced search
- /blacklight/nav contains customized/overridden views for navigation
- /catalog contains customized/overridden views for 
- -- citation
- -- homepage
- -- search form
- -- "show" page (full record view)
- -- Links sidebar widget (full record view)
- -- Contact Institution sidebar widget
- -- sidebar widget config
- /shared contains customized/overridden views for
- -- pop-up alert (beta notice)
- -- header navbar
- -- footer
- -- copy to clipboard icon

## Solr Customizations

### config/
- solr-schema.yml contains custom dynamic fields (below)
- solr-seed.json contains Wikibase data from 2023-03-17

### dynamic fields (xml)

```xml
<dynamicField name="*_display" type="string" multiValued="true" indexed="true" stored="true"/>
<dynamicField name="*_search" type="text" multiValued="true" indexed="true" stored="true"/>
<dynamicField name="*_facet" type="string" docValues="true" multiValued="true" indexed="true" stored="true"/>
<dynamicField name="*_meta" type="string" multiValued="true" indexed="true" stored="true"/>
<dynamicField name="*_link" type="string" multiValued="true" indexed="true" stored="true"/>
<dynamicField name="*_int" type="int" multiValued="true" indexed="true" stored="true"/>
```

### dynamic fields (yml)

```
 - name: "*_display" 
    type: "string" 
    multiValued: true
    indexed: true
    stored: true
  - name: "*_search" 
    type: "text" 
    multiValued: true
    indexed: true
    stored: true
  - name: "*_facet" 
    type: "string" 
    docValues: true
    multiValued: true
    indexed: true
    stored: true
  - name: "*_meta" 
    type: "string" 
    multiValued: true
    indexed: true
    stored: true
  - name: "*_link" 
    type: "string" 
    multiValued: true
    indexed: true
    stored: true
  - name: "*_int" 
    type: "int" 
    multiValued: true
    indexed: true
    stored: true
```

###
## Docker Development Environment

### Dependencies
- [Docker](https://docs.docker.com/desktop/)
- [`docker-compose`](https://docs.docker.com/compose/install/)

### Setup
1) Clone this repo `gh repo clone jefawks3/hxs-blacklight`
2) Open the Terminal and CD to repo `cd hxs-blacklight`
3) Run `docker-compose build`
4) Run `docker-compose run --rm app bundle install -j8`
5) Run `docker-compose run --rm app bundle exec rake db:migrate`
6) Run `docker-compose run --rm app bundle exec rake solr:schema:update`
7) Run `docker-compose run --rm app bundle exec rake solr:seed`
8) Run `docker-compose up`
9) Open http://localhost:3000 in the browser

If you want to add test MARC records run `docker-compose run app rake solr:marc:index_test_data`

### Changes

- Code - *No Action* - Code changes should be detected by Rails
- Migrations - Run `docker-compose run --rm app bundle exec rake db:migrate`
- Solr Schema Changes - Run `docker-compose run --rm app bundle exec rake solr:schema:update`
- Gemfile - Rerun `docker-compose run --rm app bundle install` and restart `app` container

### Links/URLs
- Web - http://localhost:3000
- Solr - http://localhost:8983/solr
- MySql -  http://localhost:3306

## Deploy to Staging Environment

Notes:
1) You only need to rebuild any images that have changes.
2) ECS is configured to run on Linux x86_64 architecture; make sure to specify the platform when building.
3) Once you have pushed your images to ECR, you will need to [deploy](#deploy-changes) the images via ECS.

### Build & Push App Image

1) Login to AWS ECR `aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 214159447841.dkr.ecr.us-east-2.amazonaws.com`
2) Build Image `ENV RAILS_MASTER_KEY=[MASTER_KEY] docker buildx build --platform linux/x86_64 -t hxs-blacklight-app --file .docker/rails.prod.Dockerfile --secret id=master_key,env=RAILS_MASTER_KEY --build-arg RAILS_PORT=80 --no-cache .`
2) Tag Image `docker tag hxs-blacklight-app:latest 214159447841.dkr.ecr.us-east-2.amazonaws.com/hxs-blacklight-app:latest`
3) Push Image `docker push 214159447841.dkr.ecr.us-east-2.amazonaws.com/hxs-blacklight-app:latest`

### Build & Push Solr Image

1) Login to AWS ECR `aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 214159447841.dkr.ecr.us-east-2.amazonaws.com`
2) Build Image `docker buildx build --platform linux/x86_64 -t hxs-blacklight-solr --file .docker/solr.prod.Dockerfile --no-cache .`
3) Tag Image `docker tag hxs-blacklight-solr:latest 214159447841.dkr.ecr.us-east-2.amazonaws.com/hxs-blacklight-solr:latest`
4) Push Image `docker push 214159447841.dkr.ecr.us-east-2.amazonaws.com/hxs-blacklight-solr:latest`

### Deploy Changes

*NOTE: Due to the way ECS handles deployment, unless you are incrementing the Task definition version, you will need to use the **Force Deployment** in [**Tips & Tricks**](#tips--tricks)*.

1) Log in to ECS
2) Select Clusters
3) Select `hxs-blacklight-[environment]`
4) Select `hxs-blacklight` under **Services**
5) Click on `Update Service`
6) Make the necessary changes

   You may need to select `Force new deployment` under **Deployment Options**
7) Click on `Update`

### Tips & Tricks

- Migrate Database: `aws ecs execute-command --region us-east-2 --cluster hxs-blacklight-staging --task [TASK_ID] --container app --command "bundle exec rake db:migrate" --interactive`
- Sync Solr Schema: `aws ecs execute-command --region us-east-2 --cluster hxs-blacklight-staging --task [TASK_ID] --container app --command "bundle exec rake solr:schema:update" --interactive`
- Force a deployment: `aws ecs update-service --force-new-deployment --region us-east-2 --cluster hxs-blacklight-staging --service hxs-blacklight`

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
