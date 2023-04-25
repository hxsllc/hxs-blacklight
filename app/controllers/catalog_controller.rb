# frozen_string_literal: true

# Blacklight controller that handles searches and document requests
class CatalogController < ApplicationController
  include Blacklight::Catalog
  include BlacklightRangeLimit::ControllerOverride
  include BlacklightAdvancedSearch::Controller

  # include Blacklight::BlacklightHelperBehavior
  # include Blacklight::ConfigurationHelperBehavior
  # def index
  # raise document_index_view_type.to_s
  # end

  configure_blacklight do |config|
    config.view_config(:list).search_bar_component = DsSearchBarComponent

    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'edismax'
    config.advanced_search[:form_solr_parameters] ||= {}
    config.advanced_search.enabled = true
    config.advanced_search[:form_solr_parameters]['facet.query'] ||= ''
    config.advanced_search[:form_solr_parameters]['facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['facet.sort'] ||= 'index'

    # The 'facet.limit' -1 value is not respected here, catalog_controller.rb configuration facet limits are still passed along to Solr. This manually adjusts the facet count to -1 for schema_provider_s and gbl_resourceType_sm
    config.advanced_search[:form_solr_parameters]['f.institution_facet.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.author_facet.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.title_facet.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.scribe_facet.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.artist_facet.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.place_facet.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.century_int.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.language_facet.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.material_facet.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.owner_facet.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.agent_facet.facet.limit'] ||= -1
    config.advanced_search[:form_solr_parameters]['f.term_facet.facet.limit'] ||= -1

    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response
    #
    ## Should the raw solr document endpoint (e.g. /catalog/:id/raw) be enabled
    # config.raw_endpoint.enabled = false

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
      rows: 10
    }

    # solr path which will be added to solr base url before the other solr params.
    # config.solr_path = 'select'
    # config.document_solr_path = 'get'

    # items to show per page, each number in the array represent another option to choose from.
    config.per_page = [10, 20, 50, 100]

    # solr field configuration for search results/index views

    config.index.document_presenter_class = TitlePresenterIndex
    config.show.document_presenter_class = TitlePresenterShow

    # config.index.title_field = 'title_recorded'
    # config.index.display_type_field = 'format'
    # config.index.thumbnail_field = 'thumbnail_path_ss'

    # solr field configuration for search results/index views
    # config.index.show_link = 'title_display'
    # config.index.record_display_type = 'format'

    # solr field configuration for document/show views
    # config.show.html_title = 'title_display'
    # config.show.heading = 'title_display'
    # config.show.display_type = 'format'

    config.add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)

    # config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)

    ### https://github.com/projectblacklight/blacklight/blob/main/app/views/catalog/_show_tools.html.erb (copy, add new panel)
    config.add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    # config.add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
    # config.add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
    config.add_show_tools_partial(:citation)

    ## https://github.com/projectblacklight/blacklight/blob/main/app/views/blacklight/nav/_bookmark.html.erb
    config.add_nav_action(:home, partial: 'blacklight/nav/home_nav_item')
    config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')
    # config.add_nav_action(:advanced, partial: 'blacklight/nav/advanced')

    # solr field configuration for document/show views
    # config.show.title_field = 'title_tsim'
    # config.show.display_type_field = 'format'
    # config.show.thumbnail_field = 'thumbnail_path_ss'

    config.add_facet_field 'institution_facet', label: 'Holding Institution', collapse: false, limit: 4
    config.add_facet_field 'title_facet', label: 'Title', limit: 5
    config.add_facet_field 'author_facet', label: 'Author', limit: 5
    config.add_facet_field 'scribe_facet', label: 'Scribe', limit: 5
    config.add_facet_field 'artist_facet', label: 'Artist', limit: 5
    config.add_facet_field 'place_facet', label: 'Place', limit: 5 # , single: true
    config.add_facet_field 'century_int', label: 'Century', limit: 5, sort: 'alpha', helper_method: :century_label

    # TESTING IMPLEMENTATION OF INTEGER DATE FIELDS AND BLACKLIGHT_RANGE_LIMIT
    # config.add_facet_field 'century_facet', label: 'Century', limit:5, sort:'alpha'
    # config.add_facet_field 'earliest_int', label: 'Earliest Date', limit:5
    # config.add_facet_field 'latest_int', label: 'Latest Date', limit:5

    # config.add_facet_field 'earliest_int', label: 'Date (Earliest)', range: {
    #  num_segments:10,
    #        assumed_boundaries: [800,1700],
    #        segments: true,
    #        maxlength: 4
    #      }, collapse:false
    # config.add_facet_field 'latest_int', label: 'Date (Latest)', range: {
    #   num_segments:10,
    #        assumed_boundaries: [800,1700],
    #        segments: true,
    #        maxlength: 4
    #      }, collapse:false

    config.add_facet_field 'language_facet', label: 'Language', limit: 5
    config.add_facet_field 'material_facet', label: 'Material', limit: 5
    config.add_facet_field 'owner_facet', label: 'Former Owner', limit: 5
    config.add_facet_field 'agent_facet', label: 'Associated Agent', limit: 5
    config.add_facet_field 'term_facet', label: 'Keywords', limit: 5
    config.add_facet_field 'images_facet', label: 'Has Images', limit: 5
    config.add_facet_field 'dated_facet', label: 'Dated', limit: 5

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'title_facet', label: 'Title'
    config.add_index_field 'author_facet', label: 'Author'
    config.add_index_field 'place_facet', label: 'Place',
                                          separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
    config.add_index_field 'date_meta', label: 'Date'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    # #external links

    # #display v3.0

    config.add_show_field 'id', label: 'DS ID', separator_options: { words_connector: '<br />', last_word_connector: '<br />' } # , accessor: :make_btn_ds
    config.add_show_field 'shelfmark_display', label: 'Shelfmark', helper_method: :search_data_link
    config.add_show_field 'title_display', label: 'Title', helper_method: :property_value
    config.add_show_field 'author_display', label: 'Author', helper_method: :search_data_link
    config.add_show_field 'scribe_display', label: 'Scribe', helper_method: :search_data_link
    config.add_show_field 'artist_display', label: 'Artist', helper_method: :search_data_link
    config.add_show_field 'place_display', label: 'Place', helper_method: :search_data_link
    config.add_show_field 'date_display', label: 'Date', helper_method: :search_data_link
    config.add_show_field 'language_display', label: 'Language', helper_method: :search_data_link
    config.add_show_field 'material_display', label: 'Material', helper_method: :search_data_link
    config.add_show_field 'physical_description_display', label: 'Physical Description',                                                          helper_method: :property_value
    config.add_show_field 'owner_display', label: 'Former Owner(s)', helper_method: :search_data_link
    config.add_show_field 'agent_display', label: 'Associated Agent(s)', helper_method: :search_data_link
    config.add_show_field 'note_display', label: 'Note', helper_method: :property_value
    config.add_show_field 'term_facet', label: 'Keyword', link_to_facet: true, helper_method: :search_term_link
    config.add_show_field 'institutional_record_link', label: 'Institutional Record', helper_method: :link_with_copy
    config.add_show_field 'iiif_manifest_link', label: 'IIIF Manifest', helper_method: :link_with_copy
    config.add_show_field 'institution_display', label: 'Holding Institution', link_to_facet: true,
                                                 helper_method: :search_link

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    config.add_search_field 'all_fields', label: 'All Fields' do |field|
      field.solr_parameters = {
        qf: 'id_search institution_search shelfmark_search title_search artist_search author_search scribe_search owner_search
    term_search language_search date_search place_search material_search physical_description_display note_display',
        pf: 'id_search institution_search shelfmark_search title_search artist_search author_search scribe_search owner_search
    term_search language_search date_search place_search material_search physical_description_display note_display'
      }
    end

    config.add_search_field 'institution', label: 'Holding Institution' do |field|
      field.solr_parameters = {
        qf: 'institution_search',
        pf: 'institution_search'
      }
    end

    config.add_search_field 'shelfmark', label: 'Shelfmark' do |field|
      field.solr_parameters = {
        qf: 'shelfmark_search',
        pf: 'shelfmark_search'
      }
    end

    config.add_search_field 'title', label: 'Title' do |field|
      field.solr_parameters = {
        qf: 'title_search',
        pf: 'title_search'
      }
    end

    config.add_search_field 'author', label: 'Author' do |field|
      field.solr_parameters = {
        qf: 'author_search',
        pf: 'author_search'
      }
    end    

    config.add_search_field 'artist', label: 'Artist' do |field|
      field.include_in_simple_select = false
      field.solr_parameters = {
        qf: 'artist_facet artist_search',
        pf: ''
      }
    end

    config.add_search_field 'scribe', label: 'Scribe' do |field|
      field.include_in_simple_select = false
      field.solr_parameters = {
        qf: 'scribe_search',
        pf: 'scribe_search'
      }
    end

    config.add_search_field 'owner', label: 'Owner(s)' do |field|
      field.include_in_simple_select = false
      field.solr_parameters = {
        qf: 'owner_search',
        pf: 'owner_search'
      }
    end   

    config.add_search_field 'agent', label: 'Agent(s)' do |field|
      field.include_in_simple_select = false
      field.solr_parameters = {
        qf: 'agent_facet',
        pf: 'agent_facet'
      }
    end       

    config.add_search_field 'place', label: 'Place' do |field|
      field.solr_parameters = {
        qf: 'place_search',
        pf: 'place_search'
      }
    end

    config.add_search_field 'date', label: 'Date' do |field|
      field.include_in_simple_select = false
      field.solr_parameters = {
        qf: 'date_search',
        pf: 'date_search'
      }
    end

   config.add_search_field 'language', label: 'Language' do |field|
      field.include_in_simple_select = false
      field.solr_parameters = {
        qf: 'language_search',
        pf: 'language_search'
      }
    end    

   config.add_search_field 'keyword', label: 'Keywords' do |field|
      field.include_in_simple_select = false
      field.solr_parameters = {
        qf: 'term_search',
        pf: 'term_search'
      }
    end    

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.
    # config.add_search_field('author') do |field|
    #  field.solr_parameters = {
    #    'spellcheck.dictionary': 'author',
    #    qf: '${author_qf}',
    #    pf: '${author_pf}'
    #  }
    # end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    # config.add_search_field('subject') do |field|
    #  field.qt = 'search'
    #  field.solr_parameters = {
    #    'spellcheck.dictionary': 'subject',
    #    qf: '${subject_qf}',
    #    pf: '${subject_pf}'
    #  }
    # end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the Solr field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case). Add the sort: option to configure a
    # custom Blacklight url parameter value separate from the Solr sort fields.
    # #config.add_sort_field 'relevance', sort: 'score desc, pub_date_si desc, title_si asc', label: 'relevance'
    # #config.add_sort_field 'year-desc', sort: 'pub_date_si desc, title_si asc', label: 'year'
    # #config.add_sort_field 'author', sort: 'author_si asc, title_si asc', label: 'author'
    # #config.add_sort_field 'title_si asc, pub_date_si desc', label: 'title'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggester
    config.autocomplete_enabled = true
    config.autocomplete_path = 'suggest'
    # if the name of the solr.SuggestComponent provided in your solrconfig.xml is not the
    # default 'mySuggester', uncomment and provide it below
    # config.autocomplete_suggester = 'mySuggester'
  end
end
