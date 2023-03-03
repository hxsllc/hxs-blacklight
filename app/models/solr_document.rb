# frozen_string_literal: true

# Represent a single document returned from Solr
class SolrDocument
	
  include Blacklight::Solr::Document
  include ActionView::Helpers::UrlHelper
  
  ## facet link example: http://localhost:3000/?f%5Binstitution_facet%5D%5B%5D=University+of+Pennsylvania

	LINK_DATA_DEFAULT = :other
	LINK_DATA_ACRONYMS = {
		wikidata: {
			domain: 'wikidata.org'
		},
		tgn: {
			host: 'vocab.getty.edu',
			path: /^\/tgn\//i
		},
		aat: {
			host: 'vocab.getty.edu',
			path: /^\/aat\//i
		},
	}.freeze

	LINK_DATA_ICON = 'https://img.icons8.com/external-sbts2018-flat-sbts2018/58/null/external-13-nodes-elastic-search-sbts2018-flat-sbts2018.png'

  def prop_iiif 
	if fetch('iiif_manifest_link',false)
	Array(fetch('iiif_manifest_link')).map do |v|
      link_to(v, v, target: '_blank', class: 'ds-ld-search')
      #"<span style='text-decoration:line-through;'>#{v}</span>".html_safe
    end
    end
  end  

  def prop_record
	if fetch('institutional_record_link',false)
	Array(fetch('institutional_record_link')).map do |v|
      link_to(v, v, target: '_blank', class: 'ds-ld-search')
      #"<span style='text-decoration:line-through;'>#{v}</span>".html_safe
    end
    end
  end    
  
  def make_btn_ds
	if fetch('id_display',false)
	Array(fetch('id_display')).map do |v|
      link_to("Wikibase #{v}", '#', class: 'btn btn-secondary')
    end
    end
  end    

  def prop_shelfmark
	if fetch('shelfmark_display',false)
	Array(fetch('shelfmark_display')).map do |v|
      #a = v.sub("PV ","")
      #"#{a}"
      data = JSON.parse(v)
      output = data["PV"]
      "#{output}"
    end
    end
  end      

  def prop_title
	if fetch('title_display',false)
	Array(fetch('title_display')).map do |v|
      #a = v.sub("PV ","")
      #"#{a}"
      data = JSON.parse(v)
      output = data["PV"]
      "#{output}"
    end
    end
  end  
  
  #V3.1 Linked Data bar with placeholder grayscale icon and #AUTH# hyperlink + AGR value
  def prop_author
	divstart = "<br><div class='ds-ld-bar'>&nbsp;" 
	divend = "</div>"
	qfield = "author_facet"
	if fetch('author_display',false)
	Array(fetch('author_display')).map do |v|
		data = JSON.parse(v)
		pv = data["PV"]
		agr = data["AGR"]
		ql = data["QL"]
		qu = data["QU"]

		if agr then qtext = "#{pv} / #{agr}" else qtext = "#{pv}" end
		if ql  
			qlink = "<a class='ds-ld-search' href='/?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" 
		else 
			qlink=""
			divstart=""
			divend=""
		end
		"#{qtext}#{divstart}#{qlink}#{linked_data_span_tag qu}#{divend}".html_safe
    end
    end
  end    

  #V3.1 Linked Data bar with placeholder grayscale icon and #AUTH# hyperlink + AGR value
  def prop_scribe
	divstart = "<br><div class='ds-ld-bar'>&nbsp;" 
	divend = "</div>"	
	qfield = "scribe_facet"
	if fetch('scribe_display',false)
	Array(fetch('scribe_display')).map do |v|
		data = JSON.parse(v)
		pv = data["PV"]
		agr = data["AGR"]
		ql = data["QL"]
		qu = data["QU"]
		if agr then qtext = "#{pv} / #{agr}" else qtext = "#{pv}" end
		if ql  
			qlink = "<a class='ds-ld-search' href='/?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" 
		else 
			qlink=""
			divstart=""
			divend=""
		end
		"#{qtext}#{divstart}#{qlink}#{linked_data_span_tag qu}#{divend}".html_safe
    end
    end
  end      

  #V3.1 Linked Data bar with placeholder grayscale icon and #AUTH# hyperlink + AGR value
  def prop_artist
	divstart = "<br><div class='ds-ld-bar'>&nbsp;" 
	divend = "</div>"	
	qfield = "artist_facet"
	if fetch('artist_display',false)
	Array(fetch('artist_display')).map do |v|
		data = JSON.parse(v)
		pv = data["PV"]
		agr = data["AGR"]
		ql = data["QL"]
		qu = data["QU"]
		if agr then qtext = "#{pv} / #{agr}" else qtext = "#{pv}" end
		if ql  
			qlink = "<a class='ds-ld-search' href='/?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" 
		else 
			qlink=""
			divstart=""
			divend=""
		end
		"#{qtext}#{divstart}#{qlink}#{linked_data_span_tag qu}#{divend}".html_safe
    end
    end
  end     
  
  #V3.1 Linked Data bar with placeholder grayscale icon and #AUTH# hyperlink + AGR value
  def prop_owner
	divstart = "<br><div class='ds-ld-bar'>&nbsp;" 
	divend = "</div>"	
	qfield = "owner_facet"
	if fetch('owner_display',false)
		Array(fetch('owner_display')).map do |v|
			data = JSON.parse(v)
			pv = data["PV"]
			agr = data["AGR"]
			ql = data["QL"]
			qu = data["QU"]

			if agr then qtext = "#{pv} / #{agr}" else qtext = "#{pv}" end
			if ql  
				qlink = "<a class='ds-ld-search' href='/?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" 
			else 
				qlink=""
				divstart=""
				divend=""
			end

			"#{qtext}#{divstart}#{qlink}#{linked_data_span_tag qu}#{divend}".html_safe
	    end #array
    end #if
  end  #def            
  
  #V3 Linked Data bar with placeholder grayscale icon and #AUTH# hyperlink
  def prop_date
	if fetch('date_display',false)
	Array(fetch('date_display')).map do |v|
		data = JSON.parse(v)
		qfield = "date_facet"
		pv = data["PV"]
		agr = data["AGR"]
		ql = data["QL"]
		qu = data["QU"]

		if agr then qtext = "#{pv} / #{agr}" else qtext = "#{pv}" end
		if ql then qlink = "<a class='ds-ld-search' href='/?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" else qlink = "" end
		if ql then divstart = "<br><div class='ds-ld-bar'>&nbsp;" else divstart="" end
		if ql then divend = "</span></div>" else divend="" end

		"#{qtext}#{divstart}#{qlink}#{linked_data_span_tag qu}#{divend}".html_safe
    end
    end
  end       
  
  #V3 Linked Data bar with placeholder grayscale icon and #AUTH# hyperlink
  def prop_language
	if fetch('language_display',false)
	Array(fetch('language_display')).map do |v|
		data = JSON.parse(v)
		qfield = "language_facet"
		pv = data["PV"]
		agr = data["AGR"]
		ql = data["QL"]
		qu = data["QU"]

		if agr then qtext = "#{pv} / #{agr}" else qtext = "#{pv}" end
		if ql then qlink = "<a class='ds-ld-search' href='/?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" else qlink = "" end
		if ql then divstart = "<br><div class='ds-ld-bar'>&nbsp;" else divstart="" end
		if ql then divend = "</span></div>" else divend="" end

		"#{qtext}#{divstart}#{qlink}#{linked_data_span_tag qu}#{divend}".html_safe
    end
    end
  end  
  
  #V3 Linked Data bar with placeholder grayscale icon and #AUTH# hyperlink
  def prop_place
	if fetch('place_display',false)
	Array(fetch('place_display')).map do |v|
		data = JSON.parse(v)
		qfield = "place_facet"
		pv = data["PV"]
		agr = data["AGR"]
		ql = data["QL"]
		qu = data["QU"]

		if agr then qtext = "#{pv} / #{agr}" else qtext = "#{pv}" end
		if ql then qlink = "<a class='ds-ld-search' href='/?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" else qlink = "" end
		if ql then divstart = "<br><div class='ds-ld-bar'>&nbsp;" else divstart="" end
		if ql then divend = "</span></div>" else divend="" end

		"#{qtext}#{divstart}#{qlink}#{linked_data_span_tag qu}#{divend}".html_safe
    end
    end
  end           
  
  #V3 Linked Data bar with placeholder grayscale icon and #AUTH# hyperlink
  def prop_material
	if fetch('material_display',false)
	Array(fetch('material_display')).map do |v|
		data = JSON.parse(v)
		qfield = "material_facet"
		pv = data["PV"]
		agr = data["AGR"]
		ql = data["QL"]
		qu = data["QU"]

		if agr then qtext = "#{pv} / #{agr}" else qtext = "#{pv}" end
		if ql then qlink = "<a class='ds-ld-search' href='/?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" else qlink = "" end
		if ql then divstart = "<br><div class='ds-ld-bar'>&nbsp;" else divstart="" end
		if ql then divend = "</span></div>" else divend="" end

		"#{qtext}#{divstart}#{qlink}#{linked_data_span_tag qu}#{divend}".html_safe
    end
    end
  end        

  #V2.0 VISUAL BAR, NO LINKED DATA
  def prop_institution
	if fetch('institution_display',false)
	divstart = "<div class='ds-bar'>&nbsp;"	
	divend = "</div>"	
	Array(fetch('institution_display')).map do |v|
		data = JSON.parse(v)
		qfield = "institution_facet"
		ql = data["QL"]
		if ql then qlink = "<a class='ds-ld-search' href='/?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" else qlink = "" end
		"#{divstart}#{qlink}#{divend}".html_safe
    end
    end
  end        
    
  #V2.0 VISUAL BAR, NO LINKED DATA
  def prop_term
	if fetch('term_facet',false)
	divstart = "<div style='background-color:#F8F4ED;border-radius:25px 25px 25px;padding:10px 10px 10px 20px;'><img src='https://img.icons8.com/ios-glyphs/30/null/search--v1.png' width='20'/>&nbsp;"
	divend = "</div>"
	tlink = ''
	Array(fetch('term_facet')).map do |v|
		#data = JSON.parse(v)
		qfield = "term_facet"
		#pv = data["PV"]
		#agr = data["AGR"]
		#ql = data["QL"]
		#qu = data["QU"]
		term = v
		tlink += "<a class='ds-ld-search' href='/?f%5B#{qfield}%5D%5B%5D=#{term}'>#{term}</a><br>"
    end
    "#{divstart}#{tlink}#{divend}".html_safe
    end
  end         
  
  #V2.0 TEXT ONLY
  def prop_description
	if fetch('physical_description_display',false)
	Array(fetch('physical_description_display')).map do |v|
		data = JSON.parse(v)
		pv = data["PV"]
		"#{pv}".html_safe
    end
    end
  end       

  #V2.0 TEXT ONLY
  def prop_note
	if fetch('note_display',false)
	Array(fetch('note_display')).map do |v|
		data = JSON.parse(v)
		pv = data["PV"]
		"#{pv}".html_safe
    end
    end
  end         
  
    
  # The following shows how to setup this blacklight document to display marc documents
  #extension_parameters[:marc_source_field] = :marc_ss
  #extension_parameters[:marc_format_type] = :marcxml
  #use_extension(Blacklight::Marc::DocumentExtension) do |document|
  #  document.key?(SolrDocument.extension_parameters[:marc_source_field])
  #end

  #field_semantics.merge!(
  #                       :title => "title_ssm",
  #                       :author => "author_ssm",
  #                       :language => "language_ssim",
  #                       :format => "format"
  #                       )



  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

	private

	def linked_data_span_tag(url)
		return nil if url.blank?

		"<span class=\"ds-ld-float\">#{linked_data_icon_tag}#{linked_data_link_tag url}<span>"
	end

	def linked_data_icon_tag
		"<img class=\"ds-ld-img\" src=\"#{LINK_DATA_ICON}\" title=\"Linked Data\" alt=\"Linked Data indicator\"/>"
	end

	def linked_data_link_tag(url)
		acronym = find_url_acronym url
		label = acronym_label acronym
		"<a class=\"ds-ld-link\" href=\"#{url}\" target=\"_blank\" title=\"Explore this term via Linked Data\">#{label}</a>"
	end

	def acronym_label(acronym)
		I18n.translate "blacklight.solr_document.link_data_acronyms.#{acronym}", default: acronym.to_s.upcase
	end

	def find_url_acronym(url, default: LINK_DATA_DEFAULT)
		uri = Addressable::URI.parse url
		LINK_DATA_ACRONYMS.keys.find(-> { default }) { |key| acronym_match? uri, LINK_DATA_ACRONYMS[key] }
	end

	def acronym_match?(uri, acronym)
		acronym.all? do |part, test|
			case test
			when Regexp
				uri.send(part).match? test
			else
				uri.send(part) === test
			end
		end
	end
end
