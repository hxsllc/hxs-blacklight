# frozen_string_literal: true

# Blacklight controller that handles searches and document requests
class CatalogController < ApplicationController
	include Blacklight::Catalog
  include BlacklightRangeLimit::ControllerOverride

	include Blacklight::Marc::Catalog
	include BlacklightAdvancedSearch::Controller
#include Blacklight::BlacklightHelperBehavior
#include Blacklight::ConfigurationHelperBehavior
#def index
#raise document_index_view_type.to_s
#end


  configure_blacklight do |config|
		config.view_config(:list).search_bar_component = DsSearchBarComponent

    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'dismax'
    config.advanced_search[:form_solr_parameters] ||= {}
    config.advanced_search.enabled = true


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
    #config.solr_path = 'select'
    #config.document_solr_path = 'get'

    # items to show per page, each number in the array represent another option to choose from.
    config.per_page = [10,20,50,100]

    # solr field configuration for search results/index views
    #config.index.title_field = 'title_recorded'
    config.index.document_presenter_class = TitlePresenterIndex
    config.show.document_presenter_class = TitlePresenterShow
    #config.index.display_type_field = 'format'
    #config.index.thumbnail_field = 'thumbnail_path_ss'

        # solr field configuration for search results/index views
		#config.index.show_link = 'title_display'
		#config.index.record_display_type = 'format'

		# solr field configuration for document/show views
		#config.show.html_title = 'title_display'
		#config.show.heading = 'title_display'
		#config.show.display_type = 'format'

    config.add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)

    #config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)

	### https://github.com/projectblacklight/blacklight/blob/main/app/views/catalog/_show_tools.html.erb (copy, add new panel)
    config.add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    #config.add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
    #config.add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
    config.add_show_tools_partial(:citation)

    ## https://github.com/projectblacklight/blacklight/blob/main/app/views/blacklight/nav/_bookmark.html.erb
    config.add_nav_action(:home, partial: 'blacklight/nav/home_nav_item')
    config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')
    #config.add_nav_action(:advanced, partial: 'blacklight/nav/advanced')

    # solr field configuration for document/show views
    #config.show.title_field = 'title_tsim'
    #config.show.display_type_field = 'format'
    #config.show.thumbnail_field = 'thumbnail_path_ss'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #
    # set :index_range to true if you want the facet pagination view to have facet prefix-based navigation
    #  (useful when user clicks "more" on a large facet and wants to navigate alphabetically across a large set of results)
    # :index_range can be an array or range of prefixes that will be used to create the navigation (note: It is case sensitive when searching values)

	config.add_facet_field 'institution_facet', label: 'Holding Institution', collapse:false, limit:4
  config.add_facet_field 'images_facet', label: 'Has Images', limit:5
	config.add_facet_field 'author_facet', label: 'Author', limit:5
	config.add_facet_field 'title_facet', label: 'Title',limit:5
	config.add_facet_field 'scribe_facet', label: 'Scribe', limit:5
	config.add_facet_field 'artist_facet', label: 'Artist', limit:5
	config.add_facet_field 'place_facet', label: 'Place', limit:5 #, single: true
	config.add_facet_field 'century_int', label: 'Century', range: {
		num_segments:10,
         assumed_boundaries: [800,1500],
         segments: true,
         maxlength: 4
       }, collapse:false	
	#config.add_facet_field 'century_int', label: 'Century', limit:5, sort:'alpha'
	config.add_facet_field 'language_facet', label: 'Language', limit:5
	config.add_facet_field 'material_facet', label: 'Material', limit:5
	config.add_facet_field 'owner_facet', label: 'Former owners', limit:5
	config.add_facet_field 'term_facet', label: 'Keywords', limit:5

    #config.add_facet_field 'subject_ssim', label: 'Topic', limit: 20, index_range: 'A'..'Z'
    #config.add_facet_field 'language_ssim', label: 'Language', limit: true
    #config.add_facet_field 'lc_1letter_ssim', label: 'Call Number'
    #config.add_facet_field 'subject_geo_ssim', label: 'Region'
    #config.add_facet_field 'subject_era_ssim', label: 'Era'

    #config.add_facet_field 'example_pivot_field', label: 'Pivot Field', pivot: ['format', 'language_ssim'], collapsing: true

    #config.add_facet_field 'example_query_facet_field', label: 'Publish Date', :query => {
    #   :years_5 => { label: 'within 5 Years', fq: "pub_date_ssim:[#{Time.zone.now.year - 5 } TO *]" },
    #   :years_10 => { label: 'within 10 Years', fq: "pub_date_ssim:[#{Time.zone.now.year - 10 } TO *]" },
    #   :years_25 => { label: 'within 25 Years', fq: "pub_date_ssim:[#{Time.zone.now.year - 25 } TO *]" }
    #}


    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'title_facet', label: 'Title'
    config.add_index_field 'author_facet', label: 'Author'
    config.add_index_field 'place_facet', label: 'Place', separator_options: { words_connector: '<br />', last_word_connector: '<br />' } 
    config.add_index_field 'date_facet', label: 'Century'
    
    #config.add_index_field 'earliest_date', label: 'Date Range (Earliest)'
    #config.add_index_field 'latest_date', label: 'Date Range (Latest)'    
    #config.add_index_field 'century_facet', label: 'Date (Authority)'
    #config.add_index_field 'place_recorded', label: 'Place (Supplied)', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }  
    #config.add_index_field 'institution_facet', label: 'Holding Institution'
    #config.add_index_field 'physical_description', label: 'Physical Description'
    #config.add_index_field 'published_vern_ssim', label: 'Published'
    #config.add_index_field 'lc_callnum_ssim', label: 'Call number'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    ##external links
    
    ##display v1
    
      ##top of display
      ##config.add_show_field 'title_recorded', label: 'Title'
      ##config.add_show_field 'id_ds', label: 'DS ID'
      ##config.add_show_field 'shelfmark', label: 'Shelfmark'
      ##config.add_show_field 'material', label: 'Material (LD)'  
    
      ##middle of display
      ##config.add_show_field 'place_recorded', label: 'Place', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
      ##config.add_show_field 'place_authority', label: 'Place (LD)', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
      ##config.add_show_field 'language_authority', label: 'Language (LD)', link_to_facet:true, separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
      ##config.add_show_field 'production_date_recorded', label: 'Production Date', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
      ##config.add_show_field 'century_authority', label: 'Century (LD)', link_to_facet:true, separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
      ##config.add_show_field 'associated_name_recorded', label: 'Names', link_to_facet:true, separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
      ##config.add_show_field 'name_authority', label: 'Names (LD)', link_to_facet:true, separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
    
      ##config.add_show_field 'physical_description', label: 'Physical Description'
      ##config.add_show_field 'term', label: 'Keywords', link_to_facet:true
      ##config.add_show_field 'subject_recorded', label: 'Subject', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
      ##config.add_show_field 'subject_authority', label: 'Subject (LD)', link_to_facet:true, separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
      ##config.add_show_field 'genre_recorded', label: 'Genre', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
      ##config.add_show_field 'genre_authority', label: 'Genre (LD)', link_to_facet:true, separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
    
      ##bottom of display 
      ##config.add_show_field 'holding_institution', label: 'Holding Institution', link_to_facet:true       

    ##display v2.0    
    
	    ##config.add_show_field 'id', label: 'DS ID', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'manuscript_holding', label: 'Manuscript Holding', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'described_manuscript', label: 'Manuscript ID', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'institution_authority', label: 'Holding Institution', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'institution', label: 'Holding Institution', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'holding_status', label: 'Holding Status', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'institutional_id', label: 'Institution ID', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'shelfmark', label: 'Shelfmark', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'institutional_record', label: 'Institutional Record', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'title', label: 'Title', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'uniform_title_authority', label: 'Uniform Title', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'uniform_title', label: 'Uniform Title', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'original_script', label: 'Original Script', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'associated_name', label: 'Associated Name(s)', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'role_authority', label: 'Role', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'instance_of', label: 'Instance Of', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'name_authority', label: 'Name', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'genre', label: 'Genre', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'subject', label: 'Subject', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'genre_authority', label: 'Genre', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'subject_authority', label: 'Subject', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'term_authority', label: 'Term', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'language', label: 'Language', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'language_authority', label: 'Language', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'date', label: 'Date', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'century_authority', label: 'Century', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'century', label: 'Century', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'dated', label: 'Dated', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'place', label: 'Place', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'place_authority', label: 'Place', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'physical_description', label: 'Physical Description', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'material', label: 'Material', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'material_authority', label: 'Material', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'note', label: 'Note', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'acknowledgements', label: 'Acknowledgements', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'date_added', label: 'Date Added', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'date_updated', label: 'Date Updated', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'latest_date', label: 'Latest Date', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'earliest_date', label: 'Earliest Date', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'start_time', label: 'Start Time', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'end_time', label: 'End Time', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'external_identifier', label: 'External Identifier', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'aat_id', label: 'AAT ID', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'iiif_manifest', label: 'IIIF Manifest', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'wikidata_qid', label: 'Wikidata ID', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'viaf_id', label: 'VIAF ID', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'external_uri', label: 'External URI', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'equivalent_property', label: 'Property ID', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'formatter_url', label: 'Formatter URL', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'subclass_of', label: 'Subclass ID', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'name_linked', label: 'Associated Name (LD)', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'author', label: 'Author', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'scribe', label: 'Scribe', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'artist', label: 'Artist', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'owner', label: 'Former Owner', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	    ##config.add_show_field 'label', label: 'Label', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
	
    ##display v3.0    
    
    	## BUTTONS AND VIEWERS
		config.add_show_field 'id', label: 'DS ID', separator_options: { words_connector: '<br />', last_word_connector: '<br />' } #, accessor: :make_btn_ds
		
		## METADATA
		config.add_show_field 'shelfmark_display', label: 'Shelfmark', separator_options: { words_connector: '<br />', two_words_connector: '<br />', last_word_connector: '<br />' }, accessor: :prop_shelfmark
		config.add_show_field 'title_display', label: 'Title', separator_options: { words_connector: '<br />', two_words_connector: '<br />', last_word_connector: '<br />' }, accessor: :prop_title
		
		# FACET LINKS, LINKED DATA
		config.add_show_field 'author_display', label: 'Author', separator_options: { words_connector: '<br />', two_words_connector: '<br />', last_word_connector: '<br />' }, accessor: :prop_author
		config.add_show_field 'scribe_display', label: 'Scribe', separator_options: { words_connector: '<br />', two_words_connector: '<br />', last_word_connector: '<br />' }, accessor: :prop_scribe
		config.add_show_field 'artist_display', label: 'Artist', separator_options: { words_connector: '<br />', two_words_connector: '<br />', last_word_connector: '<br />' }, accessor: :prop_artist
		config.add_show_field 'owner_display', label: 'Former Owner(s)', separator_options: { words_connector: '<br />', two_words_connector: '<br />', last_word_connector: '<br />' }, accessor: :prop_owner
		#config.add_show_field 'holding_status_display', label: 'Holding Status', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
		config.add_show_field 'place_display', label: 'Place', separator_options: { words_connector: '<br />', two_words_connector: '<br />', last_word_connector: '<br />' }, accessor: :prop_place
		config.add_show_field 'date_display', label: 'Date', separator_options: { words_connector: '<br />', two_words_connector: '<br />', last_word_connector: '<br />' }, accessor: :prop_date
		config.add_show_field 'language_display', label: 'Language', separator_options: { words_connector: '<br />', two_words_connector: '<br />', last_word_connector: '<br />' }, accessor: :prop_language
		config.add_show_field 'material_display', label: 'Material', separator_options: { words_connector: '<br />', two_words_connector: '<br />', last_word_connector: '<br />' }, accessor: :prop_material

		# FACET LINKS, NO LINKED DATA
		config.add_show_field 'institution_display', label: 'Holding Institution', link_to_facet: true, separator_options: { words_connector: '<br />', two_words_connector: '<br />', last_word_connector: '<br />' }, accessor: :prop_institution
		config.add_show_field 'term_facet', label: 'Keyword', link_to_facet: true, separator_options: { words_connector: '<br />', two_words_connector: '<br />', last_word_connector: '<br />' }, accessor: :prop_term

		# TEXTUAL
		config.add_show_field 'physical_description_display', label: 'Physical Description', separator_options: { words_connector: '<br />', two_words_connector: '<br />', last_word_connector: '<br />' }, accessor: :prop_description
		config.add_show_field 'note_display', label: 'Note', separator_options: { words_connector: '<br />', two_words_connector: '<br />', last_word_connector: '<br />' }, accessor: :prop_note

		# TECHNICAL
		config.add_show_field 'institutional_record_link', label: 'Institutional Record', accessor: :prop_record
		config.add_show_field 'iiif_manifest_link', label: 'IIIF Manifest'

		#config.add_show_field 'genre_display', label: 'Genre', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
		#config.add_show_field 'subject_display', label: 'Subject', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
		#config.add_show_field 'acknowledgements_display', label: 'Acknowledgements', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
    
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
		qf: '
		id_search institution_search shelfmark_search title_search artist_search author_search scribe_search owner_search 
		term_search language_search date_search place_search material_search
		institution_facet title_facet artist_facet author_facet scribe_facet owner_facet term_Facet language_facet date_facet place_facet material_facet
		',
		pf: ''
    }
  	end

	config.add_search_field 'institution', label: 'Holding Institution' do |field|
		field.solr_parameters = {
			qf: 'institution_facet institution_search',
			pf: ''
		}
	end

	config.add_search_field 'shelfmark', label: 'Shelfmark' do |field|
    	field.solr_parameters = {
		qf: 'shelfmark_search',
		pf: ''
    }
	end

	config.add_search_field 'author', label: 'Author' do |field|
		field.solr_parameters = {
			qf: 'author_facet author_search',
			pf: ''
		}
	end
  	
	config.add_search_field 'title', label: 'Title' do |field|
    	field.solr_parameters = {
		qf: 'title_facet title_search',
		pf: ''
    }
  	end  	

	config.add_search_field 'place', label: 'Production Place' do |field|
    	field.solr_parameters = {
		qf: 'place_facet place_search',
		pf: ''
    }
  	end
  	
    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.
    #config.add_search_field('author') do |field|
    #  field.solr_parameters = {
    #    'spellcheck.dictionary': 'author',
    #    qf: '${author_qf}',
    #    pf: '${author_pf}'
    #  }
    #end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    #config.add_search_field('subject') do |field|
    #  field.qt = 'search'
    #  field.solr_parameters = {
    #    'spellcheck.dictionary': 'subject',
    #    qf: '${subject_qf}',
    #    pf: '${subject_pf}'
    #  }
    #end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the Solr field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case). Add the sort: option to configure a
    # custom Blacklight url parameter value separate from the Solr sort fields.
    config.add_sort_field 'relevance', sort: 'score desc, pub_date_si desc, title_si asc', label: 'relevance'
    config.add_sort_field 'year-desc', sort: 'pub_date_si desc, title_si asc', label: 'year'
    config.add_sort_field 'author', sort: 'author_si asc, title_si asc', label: 'author'
    config.add_sort_field 'title_si asc, pub_date_si desc', label: 'title'

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
