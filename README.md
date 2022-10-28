# README

## Docker Development Environment

**Dependencies:**
- [Docker](https://docs.docker.com/desktop/)
- [`docker-compose`](https://docs.docker.com/compose/install/)

**Setup:**
1) Clone this repo `gh repo clone jefawks3/hxs-blacklight`
2) Open the Terminal and CD to repo `cd hxs-blacklight`
3) Run `docker-compose up --build`
4) Run `docker-compose run app rake db:migrate`
5) Open http://localhost:3000 in the browser

If you want to add test MARC records run `docker-compose run app rake solr:marc:index_test_data`

**Links/URLs**
- Web - http://localhost:3000
- Solr - http://localhost:8983/solr
- MySql -  http://localhost:3306
