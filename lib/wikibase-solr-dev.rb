## import Ruby functions
require 'json'
require 'csv'
require 'date'
require 'time'
require 'optparse'

ID_DS_ID                                 = "P1"
ID_MANUSCRIPT_HOLDING                    = "P2"
ID_DESCRIBED_MANUSCRIPT                  = "P3"
ID_HOLDING_INSTITUTION_IN_AUTHORITY_FILE = "P4"
ID_HOLDING_INSTITUTION_AS_RECORDED       = "P5"
ID_HOLDING_STATUS                        = "P6"
ID_INSTITUTIONAL_ID                      = "P7"
ID_SHELFMARK                             = "P8"
ID_LINK_TO_INSTITUTIONAL_RECORD          = "P9"
ID_TITLE_AS_RECORDED                     = "P10"
ID_STANDARD_TITLE                        = "P11"
ID_UNIFORM_TITLE_AS_RECORDED             = "P12"
ID_IN_ORIGINAL_SCRIPT                    = "P13"
ID_ASSOCIATED_NAME_AS_RECORDED           = "P14"
ID_ROLE_IN_AUTHORITY_FILE                = "P15"
ID_INSTANCE_OF                           = "P16"
ID_NAME_IN_AUTHORITY_FILE                = "P17"
ID_GENRE_AS_RECORDED                     = "P18"
ID_SUBJECT_AS_RECORDED                   = "P19"
ID_TERM_IN_AUTHORITY_FILE                = "P20"
ID_LANGUAGE_AS_RECORDED                  = "P21"
ID_LANGUAGE_IN_AUTHORITY_FILE            = "P22"
ID_PRODUCTION_DATE_AS_RECORDED           = "P23"
ID_PRODUCTION_CENTURY_IN_AUTHORITY_FILE  = "P24"
ID_CENTURY                               = "P25"
ID_DATED                                 = "P26"
ID_PRODUCTION_PLACE_AS_RECORDED          = "P27"
ID_PLACE_IN_AUTHORITY_FILE               = "P28"
ID_PHYSICAL_DESCRIPTION                  = "P29"
ID_MATERIAL_AS_RECORDED                  = "P30"
ID_MATERIAL_IN_AUTHORITY_FILE            = "P31"
ID_NOTE                                  = "P32"
ID_ACKNOWLEDGEMENTS                      = "P33"
ID_DATE_ADDED                            = "P34"
ID_DATE_LAST_UPDATED                     = "P35"
ID_LATEST_DATE                           = "P36"
ID_EARLIEST_DATE                         = "P37"
ID_START_TIME                            = "P38"
ID_END_TIME                              = "P39"
ID_EXTERNAL_IDENTIFIER                   = "P40"
ID_IIIF_MANIFEST                         = "P41"
ID_WIKIDATA_QID                          = "P42"
ID_VIAF_ID                               = "P43"
ID_EXTERNAL_URI                          = "P44"
ID_EQUIVALENT_PROPERTY                   = "P45"
ID_FORMATTER_URL                         = "P46"
ID_SUBCLASS_OF                           = "P47"

##
# For either an Item, a claim property, or a qualifier property, return the value
# specified by 'type'. This method works nested hashes with the structure:
# 
#   data['mainsnak']['datavalue']['value']
#
# or
#
#   data['datavalue']['value']
#
# If 'type' == 'value', return the result of the ['datavalue']['value'] chain;
# otherwise, return 'value'.
#
# Any string will work for `type`. The only special ‘type' is `value`, which returns the 
# whatever is returned by the ‘value’ key. The property value types in the DS Wikibase 
# JSON are:
#
#   'entity-type'
#   'numeric-id'
#   'id'
#   'time'
#   'timezone'
#   'before'
#   'after'
#   'precision'
#   'calendarmodel'
#
# @param [Hash] data item or claim property or qualifier property
# @param [String] type the value type to be returned
# @return [Hash,String] the result of extracting the nested data specified by type
def get_value_by_type(data, type)
  return unless data.instance_of?(Hash)

  # if `data` has a 'mainsnak', then we need to get the nested hash with a
  # 'datavalue', 'value' chain; otherwise, we assume 'data' is a hash
  # with a 'datavalue', 'chain'
  datavalue_hash = data['mainsnak'] || data

  # Be safe anyway: make sure 'datavalue_hash' isn't nil
  return unless datavalue_hash

  # if I'm right that everything at this point is a hash with a 'datavalue', 'value'
  # chain, then the following will **always** return a hash or a string; but, to be 
  # safe, make sure value is a hash if `#dig(...)` returns `nil`
  value = datavalue_hash.dig('datavalue', 'value') || {}

  return value if type == 'value'

  value['type']    
end

##
# Get the Wikibase 'instance of’ QID if there’s ‘P16’ ‘instance_of’ claim, if present.
# Otherwise, return 'nil’. 
#
# Example:
# 
#  JSON structure:
#
#      "claims":
#      {
#          "P16":
#          [
#              {
#                  "mainsnak":
#                  {
#                      "snaktype": "value",
#                      "property": "P16",
#                      "datavalue":
#                      {
#                          "value":
#                          {
#                              "entity-type": "item",
#                              "numeric-id": 17,
#                              "id": "Q17"
#                          },
#                          "type": "wikibase-entityid"
#                      },
#                      "datatype": "wikibase-item"
#                  },
#                  "type": "statement",
#                  "id": "Q18$37029DB4-8D1C-4F47-BCBB-26F0C41F1046",
#                  "rank": "normal"
#              }
#          ],
#          // ... etc. ...
#      },
#
#     instance_of = get_instance_of(claims_array) # => ‘Q17'

def get_first_instance_of(claims)
  return unless claims.instance_of?(Hash)
  return unless claims["#{ID_INSTANCE_OF}"]
  return if claims["#{ID_INSTANCE_OF}"].empty?

  # each claim property is an array, get the first one 
  claim = claims["#{ID_INSTANCE_OF}"].first

  #claim.dig('mainsnak', 'datavalue', 'value', 'numeric-id')
  get_value_by_type(claim, 'numeric-id')
end

def get_first_wikidata_id(claims)
  return unless has_wikidata_id(claims)

  # each claim property is an array, get the first one 
  claim = claims[ID_WIKIDATA_QID].first

  #claim.dig('mainsnak', 'datavalue', 'value')
  get_value_by_type(claim, 'value')
end    

def has_wikidata_id(claims)
  return unless claims.instance_of?(Hash)
  return unless claims[ID_WIKIDATA_QID]
  return if claims[ID_WIKIDATA_QID].empty?

  return true
end    

def get_first_external_uri(claims)
  return unless has_external_uri(claims)

  # each claim property is an array, get the first one 
  claim = claims[ID_EXTERNAL_URI].first

  #claim.dig('mainsnak', 'datavalue', 'value')
  get_value_by_type(claim, 'value')
end       

def has_external_uri(claims)
  return unless claims.instance_of?(Hash)
  return unless claims[ID_EXTERNAL_URI]
  return if claims[ID_EXTERNAL_URI].empty?

  return true
end     

    dir = File.dirname __FILE__
    importJSONfile = File.expand_path 'export.json', dir

    ## Load the import JSON file into a Ruby array
    data = JSON.load_file importJSONfile

    item_LABELS = {}

    ## Loop through every item from the Wikibase JSON export
    data.each do |item|

      ## Retrieve the item ID
      ## item.keys = ["type", "id", "labels", "descriptions", "aliases", "claims", "sitelinks", "lastrevid"]
      item_ID = item["id"]
      item_CLAIMS = item["claims"]
      item_INSTANCE_OF = get_first_instance_of item_CLAIMS

      # if there are no claims, we do not need the item
      next if item_CLAIMS.empty?
      next if item_INSTANCE_OF.nil?

      # items with an instance of Q4-Q17 contain reference values
      if item_INSTANCE_OF.between?(4,17) then

          p "reference"
          # Construct reference arrays for filling in Q-entity values in the main loop
          
          # Labels are the values associated with every item
          item_LABELS[item_ID] = item["labels"]["en"]["value"]

          # URI's are the Linked Data hyperlinks for terms from authority files
          has_external_uri(item_CLAIMS) ? item_URIS[item_id] = get_first_external_uri(item_CLAIMS): nil

          # Wikidata ID properties are not stored with the full URI, so you have to construct the URI
          has_wikidata_id(item_CLAIMS) ? item_URIS[item_id] = "https://www.wikidata.org/wiki/" + get_first_wikidata_id(item_CLAIMS): nil
 
      elsif item_INSTANCE_OF.between?(1,3)

          puts "---"
          puts "#{item_ID} is an instance of #{item_INSTANCE_OF}."
     
          item_CLAIMS.each_key do |propertyID|

            puts propertyID

            item_PROPERTY_ARRAY = item_CLAIMS.dig propertyID

            next if item_PROPERTY_ARRAY.nil?
            item_PROPERTY_ARRAY.each do |propertyInstance|

                item_PROPERTY_VALUE = propertyInstance&.dig "mainsnak", "datavalue", "value"

                if item_PROPERTY_VALUE.is_a?(Hash)
                    puts "This property value is a hash."
                end

                puts item_PROPERTY_VALUE

                item_PROPERTY_QUALIFIERS = propertyInstance.dig "qualifiers"
                next if item_PROPERTY_QUALIFIERS.nil?
                item_PROPERTY_QUALIFIERS.each do |qualifier,qualifierArray| # qualifier => qualifierArray

                    puts qualifier
                    puts "This property is a qualifier of #{propertyID}."

                    qualifierArray.each do |qualifierInstance|

                        item_PROPERTY_QUALIFIER_VALUE = qualifierInstance&.dig "datavalue", "value"

                        puts item_PROPERTY_QUALIFIER_VALUE

                        item_PROPERTY_QUALIFIER_VALUE_ID = item_PROPERTY_QUALIFIER_VALUE["id"]
                        
                        # check if the value_id is nil, otherwise it will cause an error
                        unless item_PROPERTY_QUALIFIER_VALUE_ID.nil?
                            item_PROPERTY_QUALIFIER_VALUE_LABEL = item_LABELS[item_PROPERTY_QUALIFIER_VALUE_ID]
                            puts "#{item_PROPERTY_QUALIFIER_VALUE_ID} = #{item_PROPERTY_QUALIFIER_VALUE_LABEL}"
                        end

                        # INSERT BUSINESS LOGIC
                        # USE PROPERTY NAMES INSTEAD OF P-VALUES
                        # STANDARD CASE AND THEN EXCEPTIONS

                    end
                end

                # INSERT BUSINESS LOGIC WHEN NO QUALIFIERS
                # USE PROPERT NAMES INSTEAD OF P-VALUES
                # STANDARD CASE AND THEN EXCEPTIONS

            end
          end 
      end
    end

p item_LABELS

