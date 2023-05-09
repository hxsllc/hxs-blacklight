# frozen_string_literal: true

## import Ruby functions
require 'json'
require 'csv'
require 'date'
require 'time'
require 'optparse'

# This script:
# => receives as input a Wikibase JSON export
# => loops through each Wikibase item
# => extracts specific fields and values
# => outputs a Solr JSON document to use in Blacklight

# Documentation suggestions:
# => Class for Wikibase?
# => Class for Solr document?
# => Pass data to class, class creates the lookups (maps, dictionaries)
# => Method on the object to retrieve X
# => ... email Doug some files for review (export.json, import.json, wikibase.rb)
# => ... receive live data

# DS2.0 Wikibase data structure overview:
#
# Items are identified by a Q-id (e.g. Q165)
# Properties are identified by a P-id (e.g. P1, P28)
# Qualifiers are child properties which describe a parent property
#
# Items..
# .. contain claims
# .. .. which contain multiple properties / multiple instances of a property
# .. .. > which contain labels (the value of the property)
# .. .. .. which may contain multiple qualifiers (linked data properties)
# .. .. .. > and multiple instances of the same qualifier
# .. .. .. .. which may contain URIs

# Within each Wikibase item, these are the expected keys:
# data.each do |item| puts item.keys
#   type
#   id
#   labels
#   descriptions
#   aliases
#   claims
#   sitelinks
#   lastrevid
#   type
#   item
#
# => type=...
# => id=Q...
# => labels=[]
# => descriptions=[]
# => aliases=[]
# => claims=[]
#   .  [Px]=[]
#      .  [mainsnak]=[]
#         .  [snaktype]=...
#         .  [property]=...
#	  .  [datavalue]=[]
#	     .  [value]=...
#	        . [entity-type]=...
#	        . [numeric-id]=...
#	        . [id]=Q...
#      .  [qualifiers]=[]

# This script outputs the following Solr dynamic fields:
# => _display (has LD syntax structure, needs to be parsed with Blacklight)
# => _search (for text search, tokenized)
# => _facet (for displaying in sidebar facets, not tokenized)
# => _link (for displaying as a hyperlink)
# => _int (for dates)
# => _meta (for plain text data)

# This script uses the arrays below to reference the numerical ID of Wikibase properties
# that will be exported to the Solr JSON document. Someone familiar with the DS2.0
# Linked Data model and Wikidata property ID's utilized will need to maintain and update this list.
# See README.md in the repo for a list of properties.

@displayFieldIDs = [1, 5, 6, 8, 10, 14, 18, 21, 23, 26, 27, 29, 30, 32, 33].freeze
@searchFieldIDs = [1, 4, 5, 8, 10, 11, 12, 13, 14, 17, 18, 21, 22, 23, 27, 28, 29, 32].freeze
@facetFieldIDs = [5, 10, 11, 14, 18, 21, 23, 25, 26, 27, 31].freeze
@linkFieldIDs = [9, 41].freeze
@intFieldIDs = [25, 36, 37].freeze

# This script uses the below variables to control input and output.
# => dir = the current directory of this file
# => importJSONfile = the file to be imported
# => outputJSONfile = the file to be output (which is loaded into Solr)
# => importPropertyFile = the file that specifies field names used in output
# => debugLabels = display all Wikibase item labels
# => debugProperties = display information about Wikibase properties
# => debugQualifiers = display information about Wikibase qualifiers

dir = File.dirname __FILE__
importJSONfile = File.expand_path 'export.json', dir
outputJSONFile = File.expand_path 'import.json', dir
importPropertyFile = File.expand_path 'property-names.csv', dir
debugLabels = false
debugProperties = false
debugQualifiers = false

$propertyNameArray={}
CSV.foreach(importPropertyFile, col_sep: ",", liberal_parsing: true) do |line|
	@propertyName = line[0]
	$propertyNameArray[@propertyName] = line[1]
end

# JAMES INSERT EXPLANATION HERE

OptionParser.new { |opts|
  opts.banner = 'Usage: wikibase_to_solr.rb [options]'

  opts.on('-i', '--wiki-export=FILE', 'The file path to the Wikibase JSON export file.') do |f|
    importJSONfile = File.expand_path f, dir
  end

  opts.on('-o', '--output=FILE', 'The file path to output the formatted Solr JSON file.') do |f|
    outputJSONFile = File.expand_path f, dir
  end

  opts.on('-v', '--verbose', 'Verbose logging') do |_v|
    debugProperties = true
    debugLabels = true
    debugQualifiers = true
  end
}.parse!

# This script includes custom functions designed to make the code more readable.
# => include_any: used to check if the variable contains certain properties
# 	 - qualPropertyId.include_any?(['P25','P36','P37'])
# => returnMDVNifNotNil: return the mainsnak-datavalue-value-numeric-id of the Wikibase property/qualifier
# => returnMDVifNotNil: return the mainsnak-datavalue-value of the Wikibase property/qualifier
# => returnDVifNOtNil: return the datavalue-value of the Wikibase property/qualifier
# => returnDVTifNotNil: return the datavalue-value-time of the Wikibase property/qualifier
# => returnIDifNotNil: return the id of the Wikibase item
# => returnPropArrayFirst: return the first instance of the Wikibase property
# => returnPropArray: return the full array of the Wikibase property
# => returnPropQuals: return the qualifiers array within a Wikibase property
# => returnLabelValue: return the en-value of the Wikibase label
# => formatSolrValue: JAMES INSERT EXPLANATION
# => generateJSONforSolr: JAMES INSERT EXPLANATION
# => createJSONforSolr: translate Wikibase property names to Solr field names, append dynamic field, and check if property should be output
# => isPropertyJSONOutput: utilize the field output arrays to determine whether a value inside the loop should be output
# => mergeWIDs: per the documentation inside the function, combine multiple Wikibase records into a single Solr object

class String
  def include_any?(array)
    array.any? { |i| include? i }
  end
end

def returnMDVNifNotNil(var)
  var&.dig('mainsnak')&.dig('datavalue')&.dig('value')&.dig('numeric-id')&.to_i
end

def returnMDVifNotNil(var)
  var&.dig('mainsnak')&.dig('datavalue')&.dig('value')
end

def returnDVifNotNil(var)
  var&.dig('datavalue')&.dig('value')
end

def returnDVTifNotNil(var)
  var&.dig('datavalue')&.dig('value')&.dig('time')
end

def returnIDifNotNil(var)
  var&.dig('id')
end

def returnPropArrayFirst(var, prop)
  var&.dig(prop)&.first
end

def returnPropArray(var, prop)
  var&.dig(prop)
end

def returnPropQuals(var)
  var&.dig('qualifiers')
end

def returnLabelValue(var)
  var&.dig('en')&.dig('value')
end

def formatSolrValue(value)
  str = value.is_a?(Array) || value.is_a?(Hash) ? JSON.generate(value) : value
  str.is_a?(String) ? str.unicode_normalize : str
end

def generateJSONforSolr(id, fieldname, value)
  formatted = formatSolrValue value
  $solrObjects[id] ||= {}
  $solrObjects[id][fieldname] ||= []
  $solrObjects[id][fieldname] << formatted unless $solrObjects[id][fieldname].include? formatted
end

def createJSONforSolr(wikibaseid, propertyid, solr_append, fieldname, value)
  pid = propertyid.tr('P', '').to_i

  # special cases for field names
  case fieldname
  when 'Scribe'
    @outputFieldName = 'scribe'
  when 'Author'
    @outputFieldName = 'author'
  when 'Former owner'
    @outputFieldName = 'owner'
  when 'Artist'
    @outputFieldName = 'artist'
  when 'Associated agent'
    @outputFieldName = 'agent'
  when ''
    @outputFieldName = if $propertyNameArray.key?(propertyid)
                         $propertyNameArray[propertyid]
                       else
                         fieldname
                       end
  end

  # check if the property should be output for the specified _append
  return unless isPropertyJSONOutput(propertyid, solr_append, value)

  # generate JSON - "fieldname_append": "value"
  generateJSONforSolr(wikibaseid, "#{@outputFieldName}#{solr_append}", value)
end

def isPropertyJSONOutput(propertyid, solr_append, value)
  pid = propertyid.tr('P', '').to_i

  ((solr_append == '_display' && @displayFieldIDs.include?(pid)) ||
       (solr_append == '_search' && @searchFieldIDs.include?(pid)) ||
       (solr_append == '_facet' && @facetFieldIDs.include?(pid)) ||
       (solr_append == '_int' && @intFieldIDs.include?(pid)) ||
       (solr_append == '_link' && @linkFieldIDs.include?(pid))) && value != ''
end

def mergeWIDs(wikibaseQID)
  ## retrieve ID from item JSON array
  # @wid = mergeWIDs(item.fetch('id'))

  # DEBUG OUTPUT FROM WIKIBASE-TO-SOLR
  # {"qid_meta": "Q644",
  # => Q644 PP P16 Q2
  # => Q644 PP P38 false
  # => -- P4 {"entity-type"=>"item", "numeric-id"=>374, "id"=>"Q374"}
  # => ---- PV University of Pennsylvania QL University of Pennsylvania QU
  # => Q644 QQ P5 University of Pennsylvania QL University of Pennsylvania QU
  # => Q644 PP P6 Q4
  # => Q644 PP P7 9959387343503681
  # => Q644 PP P8 Oversize LJS 224
  # => Q644 PP P9 https://franklin.library.upenn.edu/catalog/FRANKLIN_9959387343503681
  # },{"qid_meta": "Q645",
  # => "id": "DS55",
  # => Q645 PP P1 DS55
  # => Q645 PP P16 Q1
  # => Q645 PP P2 Q644
  # },{"qid_meta": "Q646",
  # => Q646 PP P3 Q645
  # => Q646 PP P16 Q3

  # Q646 > points to Q645 > points to Q644

  @searchDescribedRecordQID = @dsDescribedRecords.key(wikibaseQID)
  @searchHoldingRecordQID = if @searchDescribedRecordQID.nil?
                              @dsHoldingRecords.key(wikibaseQID)
                            else
                              @dsHoldingRecords.key(@widP2search)
                            end

  return wikibaseQID if @searchHoldingRecordQID.nil?

  @searchHoldingRecordQID
end

class DSItem
  attr_reader :item_data # item data is read only

  # Contants mapped to properties; call these by
  # invoking DSItem::CONSTANT; e.g., DS::PROP_DS_ID
  # Can be use in this class or outside it.
  ITEM_MANUSCRIPT                            = 'Q1'
  ITEM_HOLDING                               = 'Q2'
  ITEM_DS_20_RECORD                          = 'Q3'

  PROP_DS_ID                                 = 'P1'
  PROP_MANUSCRIPT_HOLDING                    = 'P2'
  PROP_DESCRIBED_MANUSCRIPT                  = 'P3'
  PROP_HOLDING_INSTITUTION_IN_AUTHORITY_FILE = 'P4'
  PROP_HOLDING_INSTITUTION_AS_RECORDED       = 'P5'
  PROP_HOLDING_STATUS                        = 'P6'
  PROP_INSTITUTIONAL_ID                      = 'P7'
  PROP_SHELFMARK                             = 'P8'
  PROP_LINK_TO_INSTITUTIONAL_RECORD          = 'P9'
  PROP_TITLE_AS_RECORDED                     = 'P10'
  PROP_STANDARD_TITLE                        = 'P11'
  PROP_UNIFORM_TITLE_AS_RECORDED             = 'P12'
  PROP_IN_ORIGINAL_SCRIPT                    = 'P13'
  PROP_ASSOCIATED_NAME_AS_RECORDED           = 'P14'
  PROP_ROLE_IN_AUTHORITY_FILE                = 'P15'
  PROP_INSTANCE_OF                           = 'P16'
  PROP_NAME_IN_AUTHORITY_FILE                = 'P17'
  PROP_GENRE_AS_RECORDED                     = 'P18'
  PROP_SUBJECT_AS_RECORDED                   = 'P19'
  PROP_TERM_IN_AUTHORITY_FILE                = 'P20'
  PROP_LANGUAGE_AS_RECORDED                  = 'P21'
  PROP_LANGUAGE_IN_AUTHORITY_FILE            = 'P22'
  PROP_PRODUCTION_DATE_AS_RECORDED           = 'P23'
  PROP_PRODUCTION_CENTURY_IN_AUTHORITY_FILE  = 'P24'
  PROP_CENTURY                               = 'P25'
  PROP_DATED                                 = 'P26'
  PROP_PRODUCTION_PLACE_AS_RECORDED          = 'P27'
  PROP_PLACE_IN_AUTHORITY_FILE               = 'P28'
  PROP_PHYSICAL_DESCRIPTION                  = 'P29'
  PROP_MATERIAL_AS_RECORDED                  = 'P30'
  PROP_MATERIAL_IN_AUTHORITY_FILE            = 'P31'
  PROP_NOTE                                  = 'P32'
  PROP_ACKNOWLEDGEMENTS                      = 'P33'
  PROP_DATE_ADDED                            = 'P34'
  PROP_DATE_LAST_UPDATED                     = 'P35'
  PROP_LATEST_DATE                           = 'P36'
  PROP_EARLIEST_DATE                         = 'P37'
  PROP_START_TIME                            = 'P38'
  PROP_END_TIME                              = 'P39'
  PROP_EXTERNAL_IDENTIFIER                   = 'P40'
  PROP_IIIF_MANIFEST                         = 'P41'
  PROP_WIKIDATA_QID                          = 'P42'
  # something is broken here, causing the closing `end` not match class
  # some invivsible character?
  PROP_VIAF_ID                               = 'P43'
  PROP_EXTERNAL_URI                          = 'P44'
  PROP_EQUIVALENT_PROPERTY                   = 'P45'
  PROP_FORMATTER_URL                         = 'P46'
  PROP_SUBCLASS_OF                           = 'P47'

  def initialize(item_data)
    @item_data = item_data
    @item_data.freeze
  end

  def wikibaseid
    @item_data['id']
  end

  def instance_of
    return unless (claim = find_claim PROP_INSTANCE_OF)

    # p DSItem.returnMDVIifNotNil(claim)
    DSItem.returnMDVIifNotNil(claim)
  end

  def external_uri
    # parsed value from @item_data
  end

  def wikidata_qid
    # parsed value from @item_data
  end

  def holding_wikibaseid
    # @holdings_by_id[ds_item.wikibaseid] = ds_item.holding_wikibaseid # PROP_MANUSCRIPT_HOLDING
    return unless (claim = find_claim PROP_MANUSCRIPT_HOLDING)

    # p claim
    # {"mainsnak"=>{"snaktype"=>"value", "property"=>"P2", "datavalue"=>{"value"=>{"entity-type"=>"item", "numeric-id"=>1298, "id"=>"Q1298"}, "type"=>"wikibase-entityid"}, "datatype"=>"wikibase-item"}, "type"=>"statement", "id"=>"Q1299$62D0FA16-5556-479C-8AB2-44C9511BDC31", "rank"=>"normal"}
    DSItem.returnMDVIifNotNil(claim)
  end

  def manuscript_wikibaseid
    return unless (claim = find_claim PROP_DESCRIBED_MANUSCRIPT)

    DSItem.returnMDVIifNotNil(claim)
  end

  def labels
    @item_data['labels']['en']['value']
  end

  def uri
    # parsed value from @item_data
    return unless (claim = find_claim PROP_EXTERNAL_URI)

    DSItem.returnMDVifNotNil(claim)
  end

  def find_claim(property)
    return if claims.empty?

    DSItem.returnPropArrayFirst(claims, property)
  end

  def claims
    # puts "claims"
    # puts @item_data['claims']
    @item_data['claims']
  end

  #-------------------
  # Convenience methods
  #-------------------

  def manuscript_record?
    return unless instance_of == ITEM_MANUSCRIPT # = 'Q1' contains 'P2'

    true
  end

  def holding_record?
    # p instance_of
    return unless instance_of == ITEM_HOLDING # = 'Q2'

    # p wikibaseid
    true
  end

  def ds_20_record?
    return unless instance_of == ITEM_DS_20_RECORD # = 'Q3'

    true
  end

  def core_model_item?
    return true if holding_record?
    return true if manuscript_record?
    return true if ds_20_record?
  end

  def is_item?
    wikibaseid.upcase.start_with? 'Q'
  end

  def is_property?
    wikibaseid.upcase.start_with? 'P'
  end

  ##
  # Whether this Item has claims
  def claims?
    return unless claims
    return if claims.empty?

    true
  end

  #-------------------
  # Parsing methods
  #-------------------

  # Moving parsers here as class methods; invoke them by calling:
  # DSItem.<method name>; e.g., DSItem.returnMDVNifNotNil(var)
  # These can be invoked here or anywhere

  def self.returnMDVNifNotNil(var)
    var&.dig('mainsnak')&.dig('datavalue')&.dig('value')&.dig('numeric-id')&.to_i
  end

  def self.returnMDVIifNotNil(var)
    var&.dig('mainsnak')&.dig('datavalue')&.dig('value')&.dig('id')
  end

  def self.returnMDVifNotNil(var)
    var&.dig('mainsnak')&.dig('datavalue')&.dig('value')
  end

  def self.returnDVifNotNil(var)
    var&.dig('datavalue')&.dig('value')
  end

  def self.returnDVTifNotNil(var)
    var&.dig('datavalue')&.dig('value')&.dig('time')
  end

  def self.returnIDifNotNil(var)
    var&.dig('id')
  end

  def self.returnPropArrayFirst(var, prop)
    var&.dig(prop)&.first
  end

  def self.returnPropArray(var, prop)
    var&.dig(prop)
  end

  def self.returnPropQuals(var)
    var&.dig('qualifiers')
  end

  def self.returnLabelValue(var)
    var&.dig('en')&.dig('value')
  end
end

##
# Class to hold DS lookup tables for label, URIs, holdings and manuscripts. Also
# parses records and adds them to the appropriate lookups.
class DSLookup
  def initialize
    @labels_by_id = {}
    @uris_by_id = {}
    @holdings_by_id = {}
    @manuscripts_by_id	= {}
    @ds_item_by_id = {}
  end

  #-------------------------------------------------------
  # Lookups
  #-------------------------------------------------------

  attr_reader :labels_by_id, :uris_by_id, :ds_item_by_id, :manuscripts_by_id, :holdings_by_id

  def find_labels(wikibaseid)
    @labels_by_id[wikibaseid]
  end

  def find_uri(wikibaseid)
    @uris_by_id[wikibaseid]
  end

  def find_manuscript_holding(wikibaseid)
    # @holdings_by_id[wikibaseid]
    @holdings_by_id.key(wikibaseid)
  end

  def find_described_manuscript(wikibaseid)
    # @manuscripts_by_id[wikibaseid]
    @manuscripts_by_id.key(wikibaseid)
  end

  def find_ds_item(wikibaseid)
    @ds_item_by_id[wikibaseid]
  end

  #-------------------------------------------------------
  # Record processing
  #-------------------------------------------------------

  ##
  # `item_data` is the parsed JSON. This method parses each item and then
  # adds values to the look up tables (labels, URIs, holdings and manuscripts) as
  # appropriate
  def process_item(ds_item)
    # pass each item to the method to add to list
    add_item ds_item
    add_uri ds_item
    add_label ds_item
    add_manuscript_records ds_item # = 'Q1'
    add_holding_records ds_item # = 'Q2'
  end

  def add_item(ds_item)
    @ds_item_by_id[ds_item.wikibaseid] = ds_item
  end

  def add_uri(ds_item)
    return if ds_item.uri.nil?
    return if ds_item.instance_of.nil?

    # return if ds_item.core_model_item? ## BB: let's load all URIs

    @uris_by_id[ds_item.wikibaseid] = ds_item.uri
  end

  def add_label(ds_item)
    return if ds_item.labels.nil?
    return if ds_item.instance_of.nil?

    # return if ds_item.core_model_item? ## BB: let's load all labels

    @labels_by_id[ds_item.wikibaseid] = ds_item.labels
  end

  def add_holding_records(ds_item)
    # = 'Q1' ITEM_MANUSCRIPT contains 'P2' PROP_MANUSCRIPT_HOLDING
    return unless ds_item.manuscript_record? # = 'Q1' ITEM_MANUSCRIPT

    @holdings_by_id[ds_item.wikibaseid] = ds_item.holding_wikibaseid # PROP_MANUSCRIPT_HOLDING
  end

  def add_manuscript_records(ds_item)
    #	JSON: "id": "Q1300", // "P16":["Q3":ITEM_DS_20_RECORD] , ["P3":PROP_DESCRIBED_MANUSCRIPT]:"Q1299"
    return unless ds_item.ds_20_record? # = 'Q3'

    @manuscripts_by_id[ds_item.wikibaseid] = ds_item.manuscript_wikibaseid # PROP_DESCRIBED_MANUSCRIPT
  end
end

##
# Class to hold DS Solr objects for output.
class DSSolr
  def initialize
    @solr_objects = {} # move this to the MAIN LOOP
  end

  #-------------------------------------------------------
  # Lookups
  #-------------------------------------------------------
  attr_reader :solr_objects

  #-------------------------------------------------------
  # Record processing
  #-------------------------------------------------------

  ##
  # `item_data` is the parsed JSON. This method parses each item and then
  # adds values to the look up tables (labels, URIs, holdings and manuscripts) as
  # appropriate
  def process_item(ds_item, output_wikibaseid)
    return unless ds_item.core_model_item?

    #Rails.logger.debug output_wikibaseid
    claims = ds_item.claims
    claims.each_key do |property|
      #Rails.logger.debug property
      property_claim = ds_item.find_claim property
      # if ds_item.has_qualifiers property_claim

      #	qualifier_claim = ds_item.find_qualifier property_claim
      #	p qualifier_claim
      # end

      # “Q1300"
      # => "P16"
      # => "P38"
      # => "P5"
      # => "P6"
      # => "P7"
      # => "P8"
      # => "P9"
      # "Q1300"
      # => "P1"
      # => "P16"
      # => "P2"
      # "Q1300"
      # => "P10"
      # => "P12"
      # => "P14"
      # => "P16"
      # => "P18"
      # => "P19"
      # => "P21"
      # => "P23"
      # => "P29"
      # => "P3"
      # => "P30"
      # => "P32"
      # => "P34"
      # => "P35"
      # => "P41"
    end
  end
end

# Load the import JSON file into a Ruby array
data = JSON.load_file importJSONfile # data.is_a?(Array) => true
# p data[0]
# => {"type"=>"item", "id"=>"Q1", "labels"=>{"en"=>{"language"=>"en", "value"=>"Manuscript"}}, "descriptions"=>{"en"=>{"language"=>"en", "value"=>"A manuscript"}}, "aliases"=>{}, "claims"=>{}, "sitelinks"=>{}, "lastrevid"=>2}

# Create an array containing all the DSItem objects
ds_items = data.map { |item| DSItem.new(item) }

# data.is_a?(Array) => false
# item.is_a?(DSItem) => true
# item.claims.is_a?(Hash) => true
# p item.wikibaseid
# => e.g. "Q1300"
# p item.claims
# => e.g. {"P1"=>[{"mainsnak"=>{"snaktype"=>"value", "property"=>"P1", "datavalue"=>{"value"=>"DS199", "type"=>"string"}, "datatype"=>"string"}, "type"=>"statement", "id"=>"Q1299$E99C6088-E3C3-47B6-8B8D-E9B83C5FE548", "rank"=>"normal"}], "P16"=>[{"mainsnak"=>{"snaktype"=>"value", "property"=>"P16", "datavalue"=>{"value"=>{"entity-type"=>"item", "numeric-id"=>1, "id"=>"Q1"}, "type"=>"wikibase-entityid"}, "datatype"=>"wikibase-item"}, "type"=>"statement", "id"=>"Q1299$CDB27C3A-892D-41B7-B28D-DC823A913AC5", "rank"=>"normal"}], "P2"=>[{"mainsnak"=>{"snaktype"=>"value", "property"=>"P2", "datavalue"=>{"value"=>{"entity-type"=>"item", "numeric-id"=>1298, "id"=>"Q1298"}, "type"=>"wikibase-entityid"}, "datatype"=>"wikibase-item"}, "type"=>"statement", "id"=>"Q1299$62D0FA16-5556-479C-8AB2-44C9511BDC31", "rank"=>"normal"}]}

ds_lookups = DSLookup.new

ds_items.each do |item|
  ds_lookups.process_item item # item.is_a?(DSItem) => true
end

# p ds_lookups.labels_by_id
# e.g. "Q1284"=>"DS194"
# e.g. "Q1285"=>"Quinque libri Egesippi nacione Judei de excidio iudeorum (DS194)"
# e.g. "Q1286"=>"Holding: University of Pennsylvania"

# p ds_lookups.uris_by_id
# e.g. "Q22"=>"http://vocab.getty.edu/aat/300011892"
# e.g. "Q780"=>"http://vocab.getty.edu/aat/300026098"

# p ds_lookups.ds_item_by_id
# e.g. "Q1300"=>#<DSItem:0x0000000111882860 @item_data={"type"=>"item", "id"=>"Q1300"

# p ds_lookups.holdings_by_id
# JSON: "id": "Q1299", // "P16":["Q1":ITEM_MANUSCRIPT], ["P2":PROP_MANUSCRIPT_HOLDING]:"Q1298"
# Arry: "Q1299"=>"Q1298"

# p ds_lookups.manuscripts_by_id
# JSON: "id": "Q1300", // "P16":["Q3":ITEM_DS_20_RECORD] , ["P3":PROP_DESCRIBED_MANUSCRIPT]:"Q1299"
# Arry: "Q1300"=>"Q1299"

@solr_objects = {}

ds_solr = DSSolr.new

ds_items.each do |item| # item.is_a?(DSItem) => true
  if item.core_model_item?

    # Wikibase describes a manuscript using 3 linked records > merge into a single Solr object.

    # "item"
    # "Q1298"			"P16":["Q2":ITEM_HOLDING]
    # "Q1299"			find_manuscript_holding
    # nil 				find_described_manuscript

    # "item"
    # "Q1299"			"P16":["Q1":ITEM_MANUSCRIPT]
    # nil 				find_manuscript_holding
    # "Q1300"			find_described_manuscript

    # "item"
    # "Q1300"			"P16":["Q3":ITEM_DS_20_RECORD]
    # nil 				find_manuscript_holding
    # nil 				find_described_manuscript

    # Q1298
    if item.holding_record?
      manuscript_linkedid = ds_lookups.find_manuscript_holding item.wikibaseid # Q2
      ds20record_id = ds_lookups.find_described_manuscript manuscript_linkedid
    end
    # Q1299
    if item.manuscript_record?
      ds20record_id = ds_lookups.find_described_manuscript item.wikibaseid # Q1
    end
    # Q1300
    if item.ds_20_record?
      ds20record_id = item.wikibaseid # Q3
    end
  end

  ds_solr.process_item item, ds20record_id
end

#exit

wikiItemLabels = {}
wikiItemURIS = {}

# Create lists populated with Q-id / property value pairs that are used
# to construct SOLR OBJECTS in the MAIN LOOP
@dsDescribedRecords = {}
@dsHoldingRecords = {}

data.each do |item|

	@wikibaseid = ''
	@instance = nil
	@uri = ''
	@label = ''

	## retrieve ID from item HASH array
	@wikibaseid = item.fetch('id')

	## retrieve claims from item HASH array
	@claims = JSON.parse item.dig('claims').to_json

	## try retrieving P16 from claims HASH array, if so populate @instance	     
	@P16 = returnPropArrayFirst @claims, 'P16'

	# if P16 is populated, get the instance

	@P16 ? @instance = returnMDVNifNotNil(@P16):  nil

	## try retrieving P42 from claims JSON array, if so populate @uri     
	@P42 = returnPropArrayFirst @claims, 'P42'
	@P42 ? @uri = "https://www.wikidata.org/wiki/"+returnMDVifNotNil(@P42): nil

	## try retrieving P48 from claims JSON array, if so populate @uri	     
	@P44 = returnPropArrayFirst @claims, 'P44'
	@P44 ? @uri = returnMDVifNotNil(@P44): nil

	##only populate LABELS HASH with objects matching certain "instance of" [P16] values	
	if @instance.nil? || !@instance.between?(1,3)

		# labels is a top-level property in the exported Wikibase documment
		@labelsArray = JSON.parse(item.dig('labels').to_json)
		@label = returnLabelValue @labelsArray

		#if there is a label present, populate a LABELS array
		@label ? wikiItemLabels[@wikibaseid]=@label: nil

		#if there is a URI present, populate a URIs array
		@uri ? wikiItemURIS[@wikibaseid]=@uri: nil

		if debugLabels
			puts "---"
			puts @wikibaseid
			puts @instance
			puts @label
			puts @uri
		end

	# if the instance_of = 1, 2, 3 then we want to extract the MANUSCRIPT_HOLDING (P2)
	# and DESCRIBED_MANUSCRIPT (P3) values into arrays
	elsif @instance.to_i>=1 && @instance.to_i<=3

		@P2 = returnPropArrayFirst @claims, 'P2'
		@P2 ? @dsDescribedRecords[@wikibaseid] = returnIDifNotNil(returnMDVifNotNil(@P2)):  nil
		@P3 = returnPropArrayFirst @claims, 'P3'
		@P3 ? @dsHoldingRecords[@wikibaseid] = returnIDifNotNil(returnMDVifNotNil(@P3)):  nil
	end

end


## main LOOP:
##   loop over each Wikibase object in the JSON data array
##   evaluate when "instance of" P16 >= 1 && <= 3

## main loop described:

## . take the entire JSON file and loop through each object within
## . extract the wikibase ID and its associated claims
## . investigate the claims so that we only process instance_of (P16) = Q1, Q2, Q3
## . apply logic to follow the properties that link records so that we end up with a single DS2 "record" 
##   for the Solr database
## . once we have an item we care about (P16=Q1, Q2, Q3) and a final ID for output...
## . loop through every single property inside the 'claims'
## . . usually, the data we want for the final record is inside mainsnak-datavalue-value, BUT sometimes
## . . . it is one level deeper inside an array/hash, and we extract the 'id' (e.g. Q14) and transform that into its label
## . . once we have the output value for that property, we check if there are qualifiers
## . . if there are no qualifiers, then we export it in 4 ways for Solr (_display, _search, _facet, _link)
## . . . when we are exporting, we check if that particular representation is needed, if not we don't export (to reduce total size of Solr import)
## . . if there are qualifiers, then loop through every single qualifier (which is a property of a property)
## . . . 

$solrObjects = {}

data.each do |item|
  @owid = ''
  @wikibaseid = ''
  @instance = 0
  @uri = ''
  @label = ''

  ## retrieve ID from item JSON array
  @owid = item.fetch('id')
  @wikibaseid = mergeWIDs @owid

  ## retrieve claims from item JSON array
  @claims = JSON.parse(item['claims'].to_json)

  ## try retrieving P16 from claims JSON array, if so populate @instance
  @P16 = returnPropArrayFirst(@claims, 'P16')
  @P16 ? @instance = returnMDVNifNotNil(@P16) : nil

  # #only process "instance of" [P16] values 1, 2, 3
  next unless @instance.to_i >= 1 && @instance.to_i <= 3

  generateJSONforSolr @wikibaseid, 'qid_meta', @owid

  @claims.each_key do |property|
    @propArrayX = returnPropArray(@claims, property)
    @propArrayTotal = @propArrayX.length
    @propArrayLoopCount = 0
    @propArrayX.each do |propArray|
      propArray ? @propValue = returnMDVifNotNil(propArray) : nil

      # custom properties that are not part of property-names.csv
      generateJSONforSolr @wikibaseid, 'id', @propValue if property == 'P1' && !@propValue.empty?
      generateJSONforSolr(@wikibaseid, 'images_facet', 'Yes') if property == 'P41' && !@propValue.empty?

      # check for MDV (mainsnak-datavalue-value) that looks like
      # P26 example = {"entity-type":"item","numeric-id":14,"id":"Q14"}
      if @propValue.is_a?(Hash)
        # get "id" = "Q14"
        @propID = returnIDifNotNil(@propValue)
        # translate "Q14" to its label
        @propValue = wikiItemLabels[@propID]
      end

      propArray ? @qualifiers = returnPropQuals(propArray) : nil

      if @qualifiers

        # set initial state of holding variables
        @qualID = ''
        @qualLabel = ''
        @qualURI = ''
        @qualAGR = ''
        @qualRole = ''
        @qualAuth = []
        @qualDate = ''
        @qualCentury = ''
        @qualLatest = ''
        @qualEarliest = ''
        @qualMaterial = ''

        @qualifiers.each_key do |qualPropertyId|
          @qualArray = returnPropArrayFirst(@qualifiers, qualPropertyId)
          # if P25, P36, P37 then return datavalue-value-time, otherwise return datavalue-value
          @qualValue = if qualPropertyId.include_any?(%w[P25 P36
                                                         P37])
                         returnDVTifNotNil(@qualArray)
                       else
                         returnDVifNotNil(@qualArray)
                       end

          # check for MDV (mainsnak-datavalue-value) that looks like
          # P26 example = {"entity-type":"item","numeric-id":14,"id":"Q14"}
          if @qualValue.is_a?(Hash)
            @qualID = returnIDifNotNil(@qualValue)
            @qualID ? @qualLabel = wikiItemLabels[@qualID] : nil
            @qualID ? @qualURI = wikiItemURIS[@qualID] : nil
          end

          # P10 contains qualifiers P13, P15, and P17 (agr, role, authority)
          qualPropertyId == 'P13' ? @qualAGR = @qualValue : nil
          qualPropertyId == 'P15' ? @qualRole = @qualLabel : nil

          # #there can be multiple P17s inside P10 qualifiers
          # #there can be multiple name authorities inside an associated name
          if qualPropertyId === 'P17'
            @qualAuth += @qualifiers[qualPropertyId].map do |qualifier|
              data = returnDVifNotNil qualifier
              id = returnIDifNotNil data
              wikiItemLabels[id]
            end
          end

          # P23 (..) contains qualifiers
          # => P24 (name_authority)
          # => P25 (..)
          # => P36 (..)
          # => P37 (..)
          qualPropertyId == 'P24' ? @qualDate = @qualValue : nil
          qualPropertyId == 'P25' ? @qualCentury = @qualValue : nil
          qualPropertyId == 'P36' ? @qualLatest = @qualValue : nil
          qualPropertyId == 'P37' ? @qualEarliest = @qualValue : nil

          # P30 contains qualifier P31
          qualPropertyId == 'P31' ? @qualMaterial = @qualValue : nil

          next unless debugQualifiers

          Rails.logger.debug { "#{@wikibaseid} QQ #{property} >> has qualifiers" }
          Rails.logger.debug { "-- #{qualPropertyId} #{@qualValue}" }
          Rails.logger.debug { "---- PV #{@propValue} QL #{@qualLabel} QU #{@qualURI}" }

          # end of @qualifiers loop
        end

        # most properties only have one qualifier, but P14 has 0, 1, 2, or 3 qualifiers
        # so you have to extract them from the loop
        case property
        when 'P14'

          # special data format output rules for P14 (associated name)
          # P14 is the only property-qualifier that might contain AGR (P13)
          # P14 is the only property in which the field name gets modified to the ROLE (P15)

          if @qualAGR.empty? && @qualAuth.empty?
            # when AGR and Authority are empty, we only output the Recorded Name
            createJSONforSolr(@wikibaseid, property, '_display', @qualRole, { PV: @propValue })
            createJSONforSolr(@wikibaseid, property, '_search', @qualRole, @propValue)
            createJSONforSolr(@wikibaseid, property, '_facet', @qualRole, @propValue)
          elsif @qualAGR && @qualAuth.empty?
            # when AGR is present but Name Authority is empty, we output the AGR + Recorded Name
            createJSONforSolr(@wikibaseid, property, '_display', @qualRole, { PV: @propValue, AGR: @qualAGR })
            createJSONforSolr(@wikibaseid, property, '_search', @qualRole, @propValue)
            createJSONforSolr(@wikibaseid, property, '_search', @qualRole, @qualAGR)
            createJSONforSolr(@wikibaseid, property, '_facet', @qualRole, @propValue)
          elsif @qualAGR.empty? && @qualAuth
            # when AGR is empty (normal) and Name Authority is present, we output the Recorded Name + Name Authority (Label + URI)
            @qualAuth.each do |nameAuthority|
              createJSONforSolr(@wikibaseid, property, '_display', @qualRole, { PV: @propValue, QL: nameAuthority, QU: @qualURI })
              createJSONforSolr(@wikibaseid, property, '_search', @qualRole, @propValue)
              createJSONforSolr(@wikibaseid, property, '_search', @qualRole, nameAuthority)
              createJSONforSolr(@wikibaseid, property, '_facet', @qualRole, nameAuthority)
            end
          else # @qualAGR && @qualAuth then
            # when AGR is present and Name Authority is present, we output the AGR + Recorded Name + Name Authority (Label + URI)
            @qualAuth.each do |nameAuthority|
              createJSONforSolr(@wikibaseid, property, '_display', @qualRole, { PV: @propValue, AGR: @qualAGR, QL: nameAuthority, QU: @qualURI })
              createJSONforSolr(@wikibaseid, property, '_search', @qualRole, @propValue)
              createJSONforSolr(@wikibaseid, property, '_search', @qualRole, @qualAGR)
              createJSONforSolr(@wikibaseid, property, '_search', @qualRole, nameAuthority)
              createJSONforSolr(@wikibaseid, property, '_facet', @qualRole, nameAuthority)
            end
          end
        when 'P23'
          # special data format output rules for P23 (date)
          # - P24 century_authority
          # - P25 century (UTC format)
          # - P37 earliest date (UTC format)
          # - P36 latest date (UTC format)

          if debugProperties then Rails.logger.debug do
                                    "#{@wikibaseid} QQ #{property} #{@propValue} QL #{@qualLabel} QU #{@qualURI}"
                                  end end

          generateJSONforSolr @wikibaseid, 'date_meta', @propValue if property == 'P23'
          createJSONforSolr(@wikibaseid, property, '_display', '',
                            { PV: @propValue, QL: @qualLabel, QU: @qualURI })
          createJSONforSolr(@wikibaseid, property, '_search', '', @propValue)
          createJSONforSolr(@wikibaseid, property, '_search', '', @qualLabel)
          createJSONforSolr(@wikibaseid, property, '_facet', '', @qualLabel)

          # generate _int values for Century, Earliest, and Latest, and a string version of Century for the date range facet
          createJSONforSolr(@wikibaseid, 'P25', '_int', '', Time.zone.parse(@qualCentury).year)
          createJSONforSolr(@wikibaseid, 'P37', '_int', '', Time.zone.parse(@qualEarliest).year)
          createJSONforSolr(@wikibaseid, 'P36', '_int', '', Time.zone.parse(@qualLatest).year)

        when 'P30'
          # if @debugProperties then puts "#{@wikibaseid} QQ #{property} #{@propValue} QL #{@qualLabel} QU #{@qualURI}" end
          Rails.logger.debug { "P31 material_facet #{@qualMaterial} #{@qualLabel}" } if debugProperties
          createJSONforSolr(@wikibaseid, 'P31', '_facet', '', @qualLabel)

        else
          if debugProperties then Rails.logger.debug do
                                    "#{@wikibaseid} QQ #{property} #{@propValue} QL #{@qualLabel} QU #{@qualURI}"
                                  end end
          Rails.logger.debug { "#{@wikibaseid} #{property} #{@qualLabel}" } if debugProperties
          createJSONforSolr(@wikibaseid, property, '_display', '',
                            { PV: @propValue, QL: @qualLabel, QU: @qualURI })
          createJSONforSolr(@wikibaseid, property, '_search', '', @propValue)
          createJSONforSolr(@wikibaseid, property, '_search', '', @qualLabel)
          createJSONforSolr(@wikibaseid, property, '_facet', '', @qualLabel)

        end

      # else if no @qualifiers exist
      else

        Rails.logger.debug { "#{@wikibaseid} PP #{property} #{@propValue}" } if debugProperties

        @propValueExport = @propValue.to_json

        createJSONforSolr(@wikibaseid, property, '_display', @qualRole, "{\"PV\": #{@propValueExport}}")
        createJSONforSolr(@wikibaseid, property, '_search', '', @propValue)
        createJSONforSolr(@wikibaseid, property, '_facet', '', @propValue)
        createJSONforSolr(@wikibaseid, property, '_link', '', @propValue)

        # end if @qualifiers
      end

      # end @propArrayX.each loop
    end

    # end @claims.keys.each loop
  end

  # end if instance_of = 3

  # end data loop
end

# output JSON to stdout
# here is where you could implement output batching
File.write outputJSONFile, JSON.pretty_generate($solrObjects.values)
