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

## Wikibase to Solr Script
wikibase-to-solr.rb

### property-names.csv

The fieldnames are used as the root of the Solr fieldname, combined with the appropriate dynamic field as outlined above.

In Wikibase:
- P1 = "DS ID"

In property-names.csv:
- P1 = "id"

After wikibase-to-solr.rb, in import.json:
- id, id_display, id_search

### root field names

- P1,id
- P2,manuscript_holding
- P3,described_manuscript
- P4,institution_authority
- P5,institution
- P6,holding_status
- P7,institutional_id
- P8,shelfmark
- P9,institutional_record
- P10,title
- P11,standard title
- P12,uniform_title
- P13,original_script
- P14,associated_name
- P15,role_authority
- P16,instance_of
- P17,name_authority
- P18,term
- P19,subject
- P20,term_authority
- P21,language
- P22,language_authority
- P23,date
- P24,century_authority
- P25,century
- P26,dated
- P27,place
- P28,place_authority
- P29,physical_description
- P30,material
- P31,material
- P32,note
- P33,acknowledgements
- P34,date_added
- P35,date_updated
- P36,latest
- P37,earliest
- P38,start_time
- P39,end_time
- P40,external_identifier
- P41,iiif_manifest
- P42,wikidata_qid
- P43,viaf_id
- P44,external_uri
- P45,equivalent_property
- P46,formatter_url
- P47,subclass_of

### dynamic field names

- _display (has LD syntax structure, needs to be parsed with Blacklight)
- _search (for text search, tokenized)
- _facet (for displaying in sidebar facets, not tokenized)
- _link (for displaying as a hyperlink)
- _int (for dates)
- _meta (for plain text data)

### overview (pseudo-code)

- require ruby libraries
- configure field output arrays (by P-id)
- configure general settings
- define custom functions
- load JSON
- load property-names.csv into a lookup array
- first EACH-DO = populate lookup arrays (labels, uris, p2records, p3records)
- second EACH-DO = main loop
  - fetch Wikibase item id
  - merge ids (3 Wikibase records become 1 merged Solr record)
  - load the claims
  - when the item matches instance_of=1,2,3, parse
  - evaluate all properties in the claims array
  - if the property contains qualifiers, evaluate all qualifiers inside that property
  - data transformation rules and logic for special cases (P14, P23, P25, P36, P37, P30, P31)
- output $solrObjects array as JSON to file

## Solr Data Pipeline Rake Tasks

### `rake data:ingest[force]`

Pull the latest changes from WikiBase export Git repository.

#### Parameters

- `force` [Boolean] (optional) Continue even if there are no changes to the Wiki JSON export file.

#### Environment Variables

- `WIKIBASE_REPOSITORY_PATH` (**default:** '../ds_exports') - The relative path, relative to `Rails.root` directory, to the local Wikibase Git instance.
- `WIKIBASE_REPOSITORY_URL` (**default:** 'https://github.com/DigitalScriptorium/ds-exports') - The remote location to the Wikibase export Git repository.
- `WIKIBASE_EXPORT_JSON_FILE` (**default:** 'json/ds-latest.json') - The relative location in the Git repository to the JSON export file.

#### Exit codes
- 0 - Success
- 1 - No changes

#### Overview (pseudo-code)
- Local Git directory exists?
  - Clone if does not exist.
- Execute a `git pull --ff-only`
- Get the export JSON file SHA1 hash from Git using `git object-hash [file]`
- Check to see if the hash exists in the `wikibase_export_versions` table
  - Hash exists
    - Exit with code 1 if the `force` parameter is `false`; exit 0 if `true`
  - Hash does not exist
    - Add a new record in the `wikibase_export_versons` table
    - Exit with code 0

### `rake data:convert[output, input, verbose]`

Converts the Wikibase JSON export file using the [Wikibase to Solr Script](#wikibase-to-solr-script).

#### Parameters

- `ouput` [String] (optional, **default:** 'tmp/solr_data.json') - The location relative to `Rails.root` to write the solr document JSON file.
- `input` [String] (optional, **default:** '../ds_exports/json/ds-latest.json') - The location relative to `Rails.root` to the Wikibase export JSON file.
- `verbose` [Boolean] (optional) - Write the debug output to STDOUT.

#### Environment Variables

- `WIKIBASE_REPOSITORY_PATH` (**default:** '../ds_exports') - The relative path, relative to `Rails.root` directory, to the local Wikibase Git instance.
- `WIKIBASE_EXPORT_JSON_FILE` (**default:** 'json/ds-latest.json') - The relative location in the Git repository to the JSON export file.

#### Exit codes

- 0 - Success
- 1 - Output file does not exist

#### Overview (pseudo-code)
- Delete the `output` file if it exists
- Execute `ruby wikibase-to-solr.rb -o [output] -i [input]`
- Exit 1 if `output` file does not exist; exit 0 if it does

### `rake data:seed[file]`

Safely seeds the Solr collection using the `file` JSON documents by making a backup of the collection before deleting all the records and uploading the new documents.

#### Parameters

- `file` [String] (optional, **default:** 'tmp/solr_data.json') - The location relative to `Rails.root` to the solr document JSON file.

#### Environment Variables

- `SOLR_URL` (required) - The Solr URI to the applications collection.
- `SOLR_BACKUP_TIMEOUT` (**default:** 5 minutes) - The number of seconds to wait for the Solr collection backup & restore commands to finish.
- `SOLR_BACKUP_WAIT_INTERVAL` (**default:** 1 minute) - The number of seconds to wait before checking on the backup & restore command status.
- `SOLR_BACKUP_LOCATION` (required) - The shared drive location to store the Solr Backups (Note: All instances of Solr & Zookeeper need read & write access to the shared drive. See https://solr.apache.org/guide/6_6/collections-api.html#CollectionsAPI-backup)

#### Exit Codes

- 0 Success

#### Overview (pseudo-code) 

- Parse the collection name from `ENV['SOLR_URL']`
- Validate and load the Solr documents in `file` into memory
- Create the solr collection backup and wait for the command to finish
  - raise an error if the command does not finish in the allotted time
- In a block
  - Delete all the solr documents in the collection
  - Upload the new solr documents
- Rescue from an exception
  - Restore the solr collection and wait for the command to finish
    - raise an error if the command does not finish in the allowed time
  - Reraise the exception 

### `rake data:migrate[force]`

Executes the data pipeline from start to finish. See individual commands above for more details.

#### Parameters

- `force` [Boolean] (optional) - Execute even if there are no changes to the Wikibase export JSON file.

#### Overview (psuedo-code)

- Execute [`rake data:ingest[force]`](#rake-dataingestforce)
- Execute [`rake data:convert`](#rake-dataconvertoutput-input-verbose)
- Execute [`rake data:seed`](#rake-dataseedfile)

*Note: If any command fails (non 0 exit code), the process will stop and exit with the same code.*

## Data pipeline CRON Job

The [`whenever`](https://github.com/javan/whenever) GEM is used to schedule the CRON job on the worker container in Docker.

The CRON job executes the `rake data:migrate`.

### CRON Job Configuration

The CRON job is configured in the `config/schedule.rb`

```ruby
every '0 0 * * *', mailto: 'test@example.com' do
  rake "data:migrate"
end
```

### Email Notifications

The `whenever` GEM has a built in functionality to email the CRON job output.

Change the `mailto` parameter in the CRON job configuration to the desired email recipient.

```ruby
every '0 0 * * *', mailto: 'test@example.com' do
  rake "data:migrate"
end
```

See https://github.com/javan/whenever#customize-email-recipient-with-the-mailto-environment-variable for more details.

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
6) Run `docker-compose up`
7) Log into Solr http://localhost:8983/solr
8) Create the `blacklight-core` collection (not core)
9) Update the schema to the `blacklight-core` collection if needed
10) Run `docker-compose run --rm app bundle exec rake data:migrate[true]`
11) Open http://localhost:3000 in the browser

### Changes

- Code - *No Action* - Code changes should be detected by Rails
- Migrations - Run `docker-compose run --rm app bundle exec rake db:migrate`
- Solr Schema Changes - Run `docker-compose run --rm app bundle exec rake solr1:schema:update`
- Gemfile - Rerun `docker-compose run --rm app bundle install` and restart `app` container

### Links/URLs
- Web - http://localhost:3000
- Solr - http://localhost:8983/solr
- Postgres -  http://localhost:5432

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
