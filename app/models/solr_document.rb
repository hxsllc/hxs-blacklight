# frozen_string_literal: true

# Represent a single document returned from Solr
class SolrDocument
	
  include Blacklight::Solr::Document
  include ActionView::Helpers::UrlHelper
  
  def make_btn_iiif 
	Array(fetch('iiif_manifest_link')).map do |v|
      link_to("IIIF Manifest", v, class: 'btn btn-secondary')
    end
  end  

  def make_btn_record 
	Array(fetch('institutional_record_link')).map do |v|
      link_to("Institutional Record", v, class: 'btn btn-secondary')
    end
  end    
  
  def make_btn_ds
	Array(fetch('id_display')).map do |v|
      link_to("Wikibase #{v}", '#', class: 'btn btn-secondary')
    end
  end    

  def prop_shelfmark
	Array(fetch('shelfmark_display')).map do |v|
      a = v.sub("PV ","")
      "#{a}"
    end
  end      

  def prop_title
	Array(fetch('title_display')).map do |v|
      a = v.sub("PV ","")
      "#{a}"
    end
  end  
  
  def prop_author
	Array(fetch('author_display')).map do |v|
      a = v.sub("PV ","")
      if a.include?("AGR")
      	b = a.sub("AGR ","(")
	  	if b.include?("QL")
		  c = b.sub("QL ",") (")
		  if c.include("QU")
			d = c.sub("QU ",")")
			e = d.gsub!(/#{URI::regexp}/, '')
			"#{e}"
		  else  
		    d = c.concat(")")
		    "#{d}"
		  end
		else
		  c = b.concat(")")
		  "#{c}"
		end
	  else
	    "#{a}"
	  end
    end
  end    

  def prop_scribe
	Array(fetch('scribe_display')).map do |v|
      a = v.sub("PV ","")
      if a.include?("AGR")
      	b = a.sub("AGR ","(")
	  	if b.include?("QL")
		  c = b.sub("QL ",") (")
		  if c.include("QU")
			d = c.sub("QU ",")")
			e = d.gsub!(/#{URI::regexp}/, '')
			"#{e}"
		  else  
		    d = c.concat(")")
		    "#{d}"
		  end
		else
		  c = b.concat(")")
		  "#{c}"
		end
	  else
	    "#{a}"
	  end
    end
  end      

  def prop_artist
	Array(fetch('artist_display')).map do |v|
      a = v.sub("PV ","")
      if a.include?("AGR")
      	b = a.sub("AGR ","(")
	  	if b.include?("QL")
		  c = b.sub("QL ",") (")
		  if c.include("QU")
			d = c.sub("QU ",")")
			e = d.gsub!(/#{URI::regexp}/, '')
			"#{e}"
		  else  
		    d = c.concat(")")
		    "#{d}"
		  end
		else
		  c = b.concat(")")
		  "#{c}"
		end
	  else
	    "#{a}"
	  end
    end
  end        
  
  def prop_date
	Array(fetch('date_display')).map do |v|
      a = v.sub("PV ","")
      if a.match?("/AGR|QL|QU/") 
      	b = a.sub("AGR ","(")
		c = b.sub("QL ",") (")
		d = c.sub("QU ",")")
		e = d.gsub!(/#{URI::regexp}/, '')
		"E #{e}"
	  elsif a.match?("/QL|QU/")
      	b = a.sub("QL ","(")
		c = c.sub("QU ",")")
		d = d.gsub!(/#{URI::regexp}/, '')
		"D #{e}"		
	  elsif a.include?("AGR")
      	b = a.sub("AGR ","(")
      	c = b.concat(")")	  
	    "C #{a}"
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
