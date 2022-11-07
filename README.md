# README

## Docker Development Environment

**Dependencies:**
- [Docker](https://docs.docker.com/desktop/)
- [`docker-compose`](https://docs.docker.com/compose/install/)

**Setup:**
1) Clone this repo `gh repo clone jefawks3/hxs-blacklight`
2) Open the Terminal and CD to repo `cd hxs-blacklight`
3) Run `docker-compose build`
4) Run `docker-compose run --rm app bundle install -j8`
5) Run `docker-compose run --rm app rake db:migrate`
6) Run `docker-compose up`
7) Open http://localhost:3000 in the browser

If you want to add test MARC records run `docker-compose run app rake solr:marc:index_test_data`

**Changes**

- Code - *No Action* - Code changes should be detected by Rails
- Migrations - Run `docker-compose run --rm app rake db:migrate`
- Gemfile - Rerun `docker-compose run --rm app bundle install` and restart `app` container

**Links/URLs**
- Web - http://localhost:3000
- Solr - http://localhost:8983/solr
- MySql -  http://localhost:3306
