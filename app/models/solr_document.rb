# frozen_string_literal: true

# Represent a single document returned from Solr
class SolrDocument
	
  include Blacklight::Solr::Document
  include ActionView::Helpers::UrlHelper
  
  ## facet link example: http://localhost:3000/?f%5Binstitution_facet%5D%5B%5D=University+of+Pennsylvania
  
  def iiif_strikethrough 
	if fetch('iiif_manifest_link',false)
	Array(fetch('iiif_manifest_link')).map do |v|
      #link_to("IIIF Manifest", v, class: 'btn btn-secondary')
      "<span style='text-decoration:line-through;'>#{v}</span>".html_safe
    end
    end
  end  

  def record_strikethrough 
	if fetch('institutional_record_link',false)
	Array(fetch('institutional_record_link')).map do |v|
      #link_to("Institutional Record", v, class: 'btn btn-secondary')
      "<span style='text-decoration:line-through;'>#{v}</span>".html_safe
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
  	## facet link example: http://localhost:3000/?f%5Binstitution_facet%5D%5B%5D=University+of+Pennsylvania  
	#magnify icon 1:<svg xmlns='http://www.w3.org/2000/svg' x='0px' y='0px' width='20' height='20' viewBox='0 0 30 30'> <path d='M 13 3 C 7.4889971 3 3 7.4889971 3 13 C 3 18.511003 7.4889971 23 13 23 C 15.396508 23 17.597385 22.148986 19.322266 20.736328 L 25.292969 26.707031 A 1.0001 1.0001 0 1 0 26.707031 25.292969 L 20.736328 19.322266 C 22.148986 17.597385 23 15.396508 23 13 C 23 7.4889971 18.511003 3 13 3 z M 13 5 C 17.430123 5 21 8.5698774 21 13 C 21 17.430123 17.430123 21 13 21 C 8.5698774 21 5 17.430123 5 13 C 5 8.5698774 8.5698774 5 13 5 z'></path></svg>
	#network icon 1: <svg xmlns='http://www.w3.org/2000/svg' x='0px' y='0px' width='24' height='24' viewBox='0 0 128 128'><path d='M 63.689453 7.9921875 A 12 12 0 0 0 62 31.820312 L 62 38.080078 A 26 26 0 0 0 42.560547 49.310547 L 37.220703 46.210938 A 11.79 11.79 0 0 0 38 42 A 12 12 0 1 0 35.220703 49.669922 L 40.550781 52.769531 A 26 26 0 0 0 40.550781 75.230469 L 35.210938 78.320312 A 12 12 0 1 0 38 86 A 12.12 12.12 0 0 0 37.220703 81.769531 L 42.560547 78.689453 A 26 26 0 0 0 62 89.919922 L 62 96.179688 A 12 12 0 1 0 66 96.179688 L 66 89.919922 A 26 26 0 0 0 85.439453 78.689453 L 90.769531 81.800781 A 12 12 0 1 0 102 74 A 12 12 0 0 0 92.779297 78.330078 L 87.449219 75.230469 A 26 26 0 0 0 87.449219 52.779297 L 92.810547 49.699219 A 12.09 12.09 0 1 0 90.810547 46.25 L 85.460938 49.320312 A 26 26 0 0 0 66 38.080078 L 66 31.820312 A 12 12 0 0 0 63.689453 7.9921875 z M 64.234375 12.003906 A 8 8 0 0 1 64 28 A 8 8 0 0 1 56 20 A 8 8 0 0 1 64.234375 12.003906 z M 102 34 A 8 8 0 1 1 94 42 A 8 8 0 0 1 102 34 z M 25.667969 34.007812 A 8 8 0 0 1 34 42 A 8 8 0 0 1 26 50 A 8 8 0 0 1 25.667969 34.007812 z M 63.085938 42.019531 A 22 22 0 0 1 86 64 A 22 22 0 0 1 64 86 A 22 22 0 0 1 63.085938 42.019531 z M 73.947266 56.535156 A 2 2 0 0 0 72.589844 57.050781 L 62 67.640625 L 55.410156 61.050781 A 2 2 0 0 0 52.589844 63.880859 L 60.589844 71.880859 A 2 2 0 0 0 63.410156 71.880859 L 75.410156 59.880859 A 2 2 0 0 0 73.947266 56.535156 z M 25.667969 78.007812 A 8 8 0 0 1 34 86 A 8 8 0 0 1 26 94 A 8 8 0 0 1 25.667969 78.007812 z M 101.66797 78.007812 A 8 8 0 0 1 110 86 A 8 8 0 0 1 102 94 A 8 8 0 0 1 101.66797 78.007812 z M 63.900391 100 A 8 8 0 0 1 64 100 A 8 8 0 0 1 72 108 A 8 8 0 1 1 63.900391 100 z'></path></svg>  	
	if fetch('author_display',false)
	Array(fetch('author_display')).map do |v|
		data = JSON.parse(v)
		qfield = "author_facet"		
		pv = data["PV"]
		agr = data["AGR"]
		ql = data["QL"]
		qu = data["QU"]
		if agr then qtext = "#{pv} / #{agr}" else qtext = "#{pv}" end
		if ql then qlink = "<a style='color:#665241 !important;font-weight:500;' href='?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" else qlink = "" end
		if ql then divstart = "<br><div style='background-color:#F8F4ED;border-radius:0 25px 25px 25px;padding:10px 10px 10px 20px;'><img src='https://img.icons8.com/ios-glyphs/30/null/search--v1.png' width='20'/>&nbsp;" else divstart="" end
		if qu then qhref = "<a href='#{qu}' target='_blank'><img src='https://img.icons8.com/external-sbts2018-flat-sbts2018/58/null/external-13-nodes-elastic-search-sbts2018-flat-sbts2018.png' width='24' style='float:right;margin-right:10px;'/></a>" else qhref = "" end
		if ql then divend = "</div>" else divend="" end

		"#{qtext}#{divstart}#{qlink}#{qhref}#{divend}".html_safe
		#if pv && agr && ql && qu
			#"#{pv} / #{agr} (LD: #{qlink})".html_safe
			#<div id="document-viewer" style="background-color:#F8F4ED;border-radius:25px 25px 0px 0px;">
			#<div id="alternate-versions-bar" style="padding:20px 10px 5px 20px;">
			#"#{pv} / #{agr}<br><div style='background-color:#F8F4ED;border-radius:0 0 25px 25px;padding:10px 10px 10px 20px;'><svg xmlns='http://www.w3.org/2000/svg' x='0px' y='0px' width='20' height='20' viewBox='0 0 30 30'> <path d='M 13 3 C 7.4889971 3 3 7.4889971 3 13 C 3 18.511003 7.4889971 23 13 23 C 15.396508 23 17.597385 22.148986 19.322266 20.736328 L 25.292969 26.707031 A 1.0001 1.0001 0 1 0 26.707031 25.292969 L 20.736328 19.322266 C 22.148986 17.597385 23 15.396508 23 13 C 23 7.4889971 18.511003 3 13 3 z M 13 5 C 17.430123 5 21 8.5698774 21 13 C 21 17.430123 17.430123 21 13 21 C 8.5698774 21 5 17.430123 5 13 C 5 8.5698774 8.5698774 5 13 5 z'></path></svg> #{qlink} <a href='#{qu}' target='_blank'><img src='https://img.icons8.com/external-sbts2018-flat-sbts2018/58/null/external-13-nodes-elastic-search-sbts2018-flat-sbts2018.png' width='24' style='float:right;margin-right:10px;'/></a></div>".html_safe
		#elsif pv && agr && ql
			#"#{pv} / #{agr}<br><div style='background-color:#F8F4ED;border-radius:0 0 25px 25px;padding:10px 10px 10px 20px;'><svg xmlns='http://www.w3.org/2000/svg' x='0px' y='0px' width='20' height='20' viewBox='0 0 30 30'> <path d='M 13 3 C 7.4889971 3 3 7.4889971 3 13 C 3 18.511003 7.4889971 23 13 23 C 15.396508 23 17.597385 22.148986 19.322266 20.736328 L 25.292969 26.707031 A 1.0001 1.0001 0 1 0 26.707031 25.292969 L 20.736328 19.322266 C 22.148986 17.597385 23 15.396508 23 13 C 23 7.4889971 18.511003 3 13 3 z M 13 5 C 17.430123 5 21 8.5698774 21 13 C 21 17.430123 17.430123 21 13 21 C 8.5698774 21 5 17.430123 5 13 C 5 8.5698774 8.5698774 5 13 5 z'></path></svg> #{qlink}</div>".html_safe
		#elsif pv && agr
			#"#{pv} / #{agr}"
		#elsif pv && ql && qu 
		
		#elsif pv && ql
			#"#{pv}<br><div style='background-color:#F8F4ED;border-radius:0 0 25px 25px;padding:10px 10px 10px 20px;'><svg xmlns='http://www.w3.org/2000/svg' x='0px' y='0px' width='20' height='20' viewBox='0 0 30 30'> <path d='M 13 3 C 7.4889971 3 3 7.4889971 3 13 C 3 18.511003 7.4889971 23 13 23 C 15.396508 23 17.597385 22.148986 19.322266 20.736328 L 25.292969 26.707031 A 1.0001 1.0001 0 1 0 26.707031 25.292969 L 20.736328 19.322266 C 22.148986 17.597385 23 15.396508 23 13 C 23 7.4889971 18.511003 3 13 3 z M 13 5 C 17.430123 5 21 8.5698774 21 13 C 21 17.430123 17.430123 21 13 21 C 8.5698774 21 5 17.430123 5 13 C 5 8.5698774 8.5698774 5 13 5 z'></path></svg> #{qlink}</div>".html_safe
		#end			
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
		if ql then qlink = "<a style='color:#665241 !important;font-weight:500;' href='?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" else qlink = "" end
		if ql then divstart = "<br><div style='background-color:#F8F4ED;border-radius:0 25px 25px 25px;padding:10px 10px 10px 20px;'><img src='https://img.icons8.com/ios-glyphs/30/null/search--v1.png' width='20'/>&nbsp;" else divstart="" end
		if qu then qhref = "<a href='#{qu}' target='_blank'><img src='https://img.icons8.com/external-sbts2018-flat-sbts2018/58/null/external-13-nodes-elastic-search-sbts2018-flat-sbts2018.png' width='24' style='float:right;margin-right:10px;'/></a>" else qhref = "" end
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
		if ql then qlink = "<a style='color:#665241 !important;font-weight:500;' href='?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" else qlink = "" end
		if ql then divstart = "<br><div style='background-color:#F8F4ED;border-radius:0 25px 25px 25px;padding:10px 10px 10px 20px;'><img src='https://img.icons8.com/ios-glyphs/30/null/search--v1.png' width='20'/>&nbsp;" else divstart="" end
		if qu then qhref = "<a href='#{qu}' target='_blank'><img src='https://img.icons8.com/external-sbts2018-flat-sbts2018/58/null/external-13-nodes-elastic-search-sbts2018-flat-sbts2018.png' width='24' style='float:right;margin-right:10px;'/></a>" else qhref = "" end
		if ql then divend = "</div>" else divend="" end
		"#{qtext}#{divstart}#{qlink}#{qhref}#{divend}".html_safe
    end
    end
  end        
  
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
		if ql then qlink = "<a style='color:#665241 !important;font-weight:500;' href='?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" else qlink = "" end
		if ql then divstart = "<br><div style='background-color:#F8F4ED;border-radius:0 25px 25px 25px;padding:10px 10px 10px 20px;'><img src='https://img.icons8.com/ios-glyphs/30/null/search--v1.png' width='20'/>&nbsp;" else divstart="" end
		if qu then qhref = "<a href='#{qu}' target='_blank'><img src='https://img.icons8.com/external-sbts2018-flat-sbts2018/58/null/external-13-nodes-elastic-search-sbts2018-flat-sbts2018.png' width='24' style='float:right;margin-right:10px;'/></a>" else qhref = "" end
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
		if ql then qlink = "<a style='color:#665241 !important;font-weight:500;' href='?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" else qlink = "" end
		if ql then divstart = "<br><div style='background-color:#F8F4ED;border-radius:0 25px 25px 25px;padding:10px 10px 10px 20px;'><img src='https://img.icons8.com/ios-glyphs/30/null/search--v1.png' width='20'/>&nbsp;" else divstart="" end
		if qu then qhref = "<a href='#{qu}' target='_blank'><img src='https://img.icons8.com/external-sbts2018-flat-sbts2018/58/null/external-13-nodes-elastic-search-sbts2018-flat-sbts2018.png' width='24' style='float:right;margin-right:10px;'/></a>" else qhref = "" end
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
		if ql then qlink = "<a style='color:#665241 !important;font-weight:500;' href='?f%5B#{qfield}%5D%5B%5D=#{ql}'>#{ql}</a>" else qlink = "" end
		if ql then divstart = "<br><div style='background-color:#F8F4ED;border-radius:0 25px 25px 25px;padding:10px 10px 10px 20px;'><img src='https://img.icons8.com/ios-glyphs/30/null/search--v1.png' width='20'/>&nbsp;" else divstart="" end
		if qu then qhref = "<a href='#{qu}' target='_blank'><img src='https://img.icons8.com/external-sbts2018-flat-sbts2018/58/null/external-13-nodes-elastic-search-sbts2018-flat-sbts2018.png' width='24' style='float:right;margin-right:10px;'/></a>" else qhref = "" end
		if ql then divend = "</div>" else divend="" end
		"#{qtext}#{divstart}#{qlink}#{qhref}#{divend}".html_safe
    end
    end
  end        
  
  def prop_description
	if fetch('physical_description_display',false)
	Array(fetch('physical_description_display')).map do |v|
		data = JSON.parse(v)
		pv = data["PV"]
		"#{pv}".html_safe
    end
    end
  end       
  
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
