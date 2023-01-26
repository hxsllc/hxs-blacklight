# frozen_string_literal: true

# Represent a single document returned from Solr
class SolrDocument
	
  include Blacklight::Solr::Document
  include ActionView::Helpers::UrlHelper
  
  ## facet link example: http://localhost:3000/?f%5Binstitution_facet%5D%5B%5D=University+of+Pennsylvania
  
  def prop_iiif 
	if fetch('iiif_manifest_link',false)
	Array(fetch('iiif_manifest_link')).map do |v|
      link_to(v, v, target: '_blank', class: '')
      #"<span style='text-decoration:line-through;'>#{v}</span>".html_safe
    end
    end
  end  

  def prop_record
	if fetch('institutional_record_link',false)
	Array(fetch('institutional_record_link')).map do |v|
      link_to(v, v, target: '_blank', class: '')
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
  
  def prop_author
	if fetch('author_display',false)
	Array(fetch('author_display')).map do |v|
		data = JSON.parse(v)
		qfield = "author_facet"		
		pv = data["PV"]
		agr = data["AGR"]
		ql = data["QL"]
		qu = data["QU"]
		if agr then qtext = "#{pv} / #{agr}" else qtext = "#{pv}" end
		if ql then qlink = "<a class='ds-ld-link' href='/?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" else qlink = "" end
		if ql then divstart = "<br><div class='ds-ld-bar'>&nbsp;" else divstart="" end
		if qu then qhref = "<a href='#{qu}' target='_blank' title='Explore this term via Linked Data'>
			<img class='ds-ld-float' src='https://img.icons8.com/external-sbts2018-flat-sbts2018/58/null/external-13-nodes-elastic-search-sbts2018-flat-sbts2018.png'/></a>" else qhref = "" end
		if ql then divend = "</div>" else divend="" end
		"#{qtext}#{divstart}#{qlink}#{qhref}#{divend}".html_safe
    end
    end
  end    

  def prop_scribe
	if fetch('scribe_display',false)
	Array(fetch('scribe_display')).map do |v|
		data = JSON.parse(v)
		qfield = "scribe_facet"
		pv = data["PV"]
		agr = data["AGR"]
		ql = data["QL"]
		qu = data["QU"]
		if agr then qtext = "#{pv} / #{agr}" else qtext = "#{pv}" end
		if ql then qlink = "<a class='ds-ld-link' href='/?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" else qlink = "" end
		if ql then divstart = "<br><div class='ds-ld-bar'>&nbsp;" else divstart="" end
		if qu then qhref = "<a href='#{qu}' target='_blank' title='Explore this term via Linked Data'>
			<img class='ds-ld-float' src='https://img.icons8.com/external-sbts2018-flat-sbts2018/58/null/external-13-nodes-elastic-search-sbts2018-flat-sbts2018.png'/></a>" else qhref = "" end
		if ql then divend = "</div>" else divend="" end
		"#{qtext}#{divstart}#{qlink}#{qhref}#{divend}".html_safe
    end
    end
  end      

  def prop_artist
	if fetch('artist_display',false)
	Array(fetch('artist_display')).map do |v|
		data = JSON.parse(v)
		qfield = "artist_facet"
		pv = data["PV"]
		agr = data["AGR"]
		ql = data["QL"]
		qu = data["QU"]
		if agr then qtext = "#{pv} / #{agr}" else qtext = "#{pv}" end
		if ql then qlink = "<a class='ds-ld-link' href='/?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" else qlink = "" end
		if ql then divstart = "<br><div class='ds-ld-bar'>&nbsp;" else divstart="" end
		if qu then qhref = "<a href='#{qu}' target='_blank' title='Explore this term via Linked Data'>
			<img class='ds-ld-float' src='https://img.icons8.com/external-sbts2018-flat-sbts2018/58/null/external-13-nodes-elastic-search-sbts2018-flat-sbts2018.png'/></a>" else qhref = "" end
		if ql then divend = "</div>" else divend="" end
		"#{qtext}#{divstart}#{qlink}#{qhref}#{divend}".html_safe
    end
    end
  end     
  
  def prop_owner
	if fetch('owner_display',false)
		divstart = "<br><div class='ds-ld-bar'>&nbsp;" 
		divend = "</div>"	
		qfield = "owner_facet"	
		Array(fetch('owner_display')).map do |v|
			data = JSON.parse(v)
			pv = data["PV"]
			agr = data["AGR"]
			ql = data["QL"]
			qu = data["QU"]
			if agr then qtext = "#{pv} / #{agr}" else qtext = "#{pv}" end
			if ql  
				qlink = "<a class='ds-ld-link' href='/?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" 
			else 
				qlink=""
				divstart=""
				divend=""
			end
			if qu then qhref = "<a href='#{qu}' target='_blank' title='Explore this term via Linked Data'><img class='ds-ld-float' src='https://img.icons8.com/external-sbts2018-flat-sbts2018/58/null/external-13-nodes-elastic-search-sbts2018-flat-sbts2018.png'/></a>" else qhref="" end
			"#{qtext}#{divstart}#{qlink}#{qhref}#{divend}".html_safe
	    end #array
    end #if
  end  #def            
  
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
		if ql then qlink = "<a class='ds-ld-link' href='/?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" else qlink = "" end
		if ql then divstart = "<br><div class='ds-ld-bar'>&nbsp;" else divstart="" end
		if qu then qhref = "<a href='#{qu}' target='_blank' title='Explore this term via Linked Data'>
			<img class='ds-ld-float' src='https://img.icons8.com/external-sbts2018-flat-sbts2018/58/null/external-13-nodes-elastic-search-sbts2018-flat-sbts2018.png'/></a>" else qhref = "" end
		if ql then divend = "</div>" else divend="" end
		"#{qtext}#{divstart}#{qlink}#{qhref}#{divend}".html_safe
    end
    end
  end       
  
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
		if ql then qlink = "<a class='ds-ld-link' href='/?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" else qlink = "" end
		if ql then divstart = "<br><div class='ds-ld-bar'>&nbsp;" else divstart="" end
		if qu then qhref = "<a href='#{qu}' target='_blank' title='Explore this term via Linked Data'>
			<img class='ds-ld-float' src='https://img.icons8.com/external-sbts2018-flat-sbts2018/58/null/external-13-nodes-elastic-search-sbts2018-flat-sbts2018.png'/></a>" else qhref = "" end
		if ql then divend = "</div>" else divend="" end
		"#{qtext}#{divstart}#{qlink}#{qhref}#{divend}".html_safe
    end
    end
  end  
  
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
		if ql then qlink = "<a class='ds-ld-link' href='/?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" else qlink = "" end
		if ql then divstart = "<br><div class='ds-ld-bar'>&nbsp;" else divstart="" end
		if qu then qhref = "<a href='#{qu}' target='_blank' title='Explore this term via Linked Data'>
			<img class='ds-ld-float' src='https://img.icons8.com/external-sbts2018-flat-sbts2018/58/null/external-13-nodes-elastic-search-sbts2018-flat-sbts2018.png'/></a>" else qhref = "" end
		if ql then divend = "</div>" else divend="" end
		"#{qtext}#{divstart}#{qlink}#{qhref}#{divend}".html_safe
    end
    end
  end           
  
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
		if ql then qlink = "<a class='ds-ld-link' href='/?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" else qlink = "" end
		if ql then divstart = "<br><div class='ds-ld-bar'>&nbsp;" else divstart="" end
		if qu then qhref = "<a href='#{qu}' target='_blank' title='Explore this term via Linked Data'>
			<img class='ds-ld-float' src='https://img.icons8.com/external-sbts2018-flat-sbts2018/58/null/external-13-nodes-elastic-search-sbts2018-flat-sbts2018.png'/></a>" else qhref = "" end
		if ql then divend = "</div>" else divend="" end
		"#{qtext}#{divstart}#{qlink}#{qhref}#{divend}".html_safe
    end
    end
  end        

  # VISUAL BAR, NO LINKED DATA
  def prop_institution
	if fetch('institution_display',false)
	divstart = "<div class='ds-bar'>&nbsp;"	
	divend = "</div>"	
	Array(fetch('institution_display')).map do |v|
		data = JSON.parse(v)
		qfield = "institution_facet"
		ql = data["QL"]
		if ql then qlink = "<a class='ds-ld-link' href='/?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" else qlink = "" end
		"#{divstart}#{qlink}#{divend}".html_safe
    end
    end
  end        
    
  # VISUAL BAR, NO LINKED DATA
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
		tlink += "<a href='/?f%5B#{qfield}%5D%5B%5D=#{term}'>#{term}</a><br>"
    end
    "#{divstart}#{tlink}#{divend}".html_safe
    end
  end         
  
  # TEXT ONLY
  def prop_description
	if fetch('physical_description_display',false)
	Array(fetch('physical_description_display')).map do |v|
		data = JSON.parse(v)
		pv = data["PV"]
		"#{pv}".html_safe
    end
    end
  end       

  # TEXT ONLY  
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
     
end
