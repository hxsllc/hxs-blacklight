ARG SOLR_VERSION=9.0.0

FROM solr:${SOLR_VERSION}

ARG SOLR_PORT=8983

# Copy Solr Configuration from Blacklight
COPY ../solr/conf /opt/solr/conf

EXPOSE ${SOLR_PORT}
