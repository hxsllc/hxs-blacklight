## RUBY FUNCTIONS

    require 'json'
    require 'csv'
    require 'date'
    require 'time'
    require 'optparse'

## CONSTANTS

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

## HELPER METHODS

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

      # {"snaktype"=>"value", "property"=>"P16", "datavalue"=>{"value"=>{"entity-type"=>"item", "numeric-id"=>3, "id"=>"Q3"}, "type"=>"wikibase-entityid"}, "datatype"=>"wikibase-item"}

      # if I'm right that everything at this point is a hash with a 'datavalue', 'value'
      # chain, then the following will **always** return a hash or a string; but, to be 
      # safe, make sure value is a hash if `#dig(...)` returns `nil`
      value = datavalue_hash.dig('datavalue', 'value') || {}

      return value if type == 'value'

      value[type]    
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
      return unless claims[ID_INSTANCE_OF]
      return if claims[ID_INSTANCE_OF].empty?

      # each claim property is an array, get the first one 
      claim = claims[ID_INSTANCE_OF].first

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

    def get_hash_value(value)
      if value.is_a?(Hash)
        if value["id"]
          item_VALUE_ID = value["id"]
          item_VALUE = $item_LABELS[item_VALUE_ID]
          item_URI = $item_URIS[item_VALUE_ID]
        elsif value["time"]
          item_VALUE = value["time"]
        end 
      end
      return item_VALUE
    end

    def get_hash_uri(value)
      if value.is_a?(Hash)
        if value["id"]
          item_VALUE_ID = value["id"]
          item_VALUE = $item_LABELS[item_VALUE_ID]
          item_URI = $item_URIS[item_VALUE_ID]
        elsif value["time"]
          item_VALUE = value["time"]
        end 
      end
      return item_URI
    end

## INPUT / OUTPUT CONFIGURATION

    dir = File.dirname __FILE__
    importJSONfile = File.expand_path 'export-dev-0302.json', dir
    sampleOutput = true  

## LOAD DATA

    data = JSON.load_file importJSONfile

## CREATE LOOKUP ARRAYS

    $item_LABELS = {}
    $item_URIS = {}

## POPULATE LOOKUP ARRAYS

    ## Loop through every item from the Wikibase JSON export to populate item_LABELS and item_URIS
    data.each do |item|

      ## item.keys = ["type", "id", "labels", "descriptions", "aliases", "claims", "sitelinks", "lastrevid"]

      ## Retrieve the item ID (value)
      item_ID = item["id"]

      ## Retrieve the item claims (deep array)
      item_CLAIMS = item["claims"]

      ## Retrieve the ID_INSTANCE_OF (deep dig into claims via get_first_instance_of method)
      item_INSTANCE_OF = get_first_instance_of item_CLAIMS

      ## Unlikely, but if there are no claims or ID_INSTANCE_OF, skip to the next item
      next if item_CLAIMS.empty?
      next if item_INSTANCE_OF.nil?

      # Wikibase items with an ID_INSTANCE_OF = Q4-Q17 contain "lookup values" that we want to use when constructing the Solr item
      if item_INSTANCE_OF.between?(4,17) then

          # Construct reference arrays for filling in Q-entity values in the main loop
          
          # Labels are the text string values associated with every item, which we often use in the Solr item values
          $item_LABELS[item_ID] = item["labels"]["en"]["value"]

          # URI's are the Linked Data entity URLs, generally terms from Linked Data Authority's such as VIAF
          has_external_uri(item_CLAIMS) ? $item_URIS[item_ID] = get_first_external_uri(item_CLAIMS): nil

          # Wikidata ID properties are not being stored with the full URL, so we have to append the a base URL to the stored value
          has_wikidata_id(item_CLAIMS) ? $item_URIS[item_ID] = "https://www.wikidata.org/wiki/" + get_first_wikidata_id(item_CLAIMS): nil

      end
    end

## OUTPUT WIKIBASE VALUES

    ## Loop through every item from the Wikibase JSON export to generate Solr items
    data.each do |item|

      ## item.keys = ["type", "id", "labels", "descriptions", "aliases", "claims", "sitelinks", "lastrevid"]

      ## Retrieve the item ID (value)
      item_ID = item["id"]

      ## Retrieve the item claims (deep array)
      item_CLAIMS = item["claims"]

      ## Retrieve the ID_INSTANCE_OF (deep dig into claims via get_first_instance_of method)
      item_INSTANCE_OF = get_first_instance_of item_CLAIMS

      if sampleOutput then
        puts "---"
        puts "Wikibase item ID: #{item_ID}"
        puts "Item instance: #{item_INSTANCE_OF}"
      end

      ## Unlikely, but if there are no claims, skip to the next item
      next if item_CLAIMS.empty?
      next if item_INSTANCE_OF.nil?

      # Wikibase items with an ID_INSTANCE_OF = Q1-Q3 contain the manuscript data that we want to use when constructing the Solr item
      next unless item_INSTANCE_OF.between?(1,3)

      if sampleOutput then
        puts "Property keys:"
        puts "  #{item_CLAIMS.keys}"
      end

      # Wikibase item claims array contains an arbitrary list of property ID's (P1-P47)     
      item_CLAIMS.each_key do |propertyID|

        # Each property ID has an array with zero, one, or many values
        item_PROPERTY_ARRAY = item_CLAIMS.dig propertyID

        # Skip ahead if the array has zero elements/data in it
        next if item_PROPERTY_ARRAY.nil?

          puts "  #{propertyID} instances: #{item_PROPERTY_ARRAY.length()}" if sampleOutput

        # Loop through each instance of a property
        item_PROPERTY_ARRAY.each do |propertyInstance|

            # Retrieve the actual text string value (or Q-entity reference) that we use for the Solr item
            item_PROPERTY_VALUE = propertyInstance&.dig "mainsnak", "datavalue", "value"

            # When the retrieved value is a hash/array, that means we have to dig one level further to retrieve the value we want
            # Translation logic for PROPERTY values that are not a text string in datavalue-value are slightly different than qualifiers
            if item_PROPERTY_VALUE.is_a?(Hash)

                if item_PROPERTY_VALUE["id"]
                  # When the hash has an "id" field, we want that (it is the Q-id, e.g. Q1, Q942)
                  item_PROPERTY_VALUE = item_PROPERTY_VALUE["id"]
                elsif item_PROPERTY_VALUE["time"]
                  # When the hash has a "time" field, we want that value
                  item_PROPERTY_VALUE = get_hash_value(item_PROPERTY_VALUE)
                end
                
            end

            puts "  ^-- #{propertyID} = #{item_PROPERTY_VALUE}" if sampleOutput 

            # Each property ID may be further described by an array of qualifiers, which are properties
            item_PROPERTY_QUALIFIERS = propertyInstance.dig "qualifiers"

            # Skip ahead if there are no qualifiers
            next if item_PROPERTY_QUALIFIERS.nil?

              if sampleOutput then
                puts "    Qualifier keys:"
                puts "    #{item_PROPERTY_QUALIFIERS.keys}"
              end

            # Loop through each qualifier ID in the qualifier array
            item_PROPERTY_QUALIFIERS.each do |qualifier,qualifierArray| # qualifier => qualifierArray

                puts "    #{qualifier} instances: #{qualifierArray.length()}" if sampleOutput  
                # Each qualifier may have multiple instances of data within it, e.g. multiple authors
                qualifierArray.each do |qualifierInstance|

                    # Retrieve the value that we use for the Solr item
                    item_PROPERTY_QUALIFIER_VALUE = qualifierInstance&.dig "datavalue", "value"

                    # When the retrieved value is a hash/array, that means we have to dig one level further to retrieve the value we want
                    # Translation logic for QUALIFIER values that are not a text string in datavalue-value are slightly different than qualifiers
                    if item_PROPERTY_QUALIFIER_VALUE.is_a?(Hash)

                        if item_PROPERTY_QUALIFIER_VALUE["id"]
                          item_PROPERTY_QUALIFIER_VALUE_ID = item_PROPERTY_QUALIFIER_VALUE["id"]
                          item_PROPERTY_QUALIFIER_VALUE_URI = get_hash_uri(item_PROPERTY_QUALIFIER_VALUE)
                          item_PROPERTY_QUALIFIER_VALUE = get_hash_value(item_PROPERTY_QUALIFIER_VALUE)
                          qualifierDebug = "    ^-- #{qualifier} = #{item_PROPERTY_QUALIFIER_VALUE_ID} > #{item_PROPERTY_QUALIFIER_VALUE} < #{item_PROPERTY_QUALIFIER_VALUE_URI}"
                        end

                        if item_PROPERTY_QUALIFIER_VALUE["time"]
                          item_PROPERTY_QUALIFIER_VALUE = get_hash_value(item_PROPERTY_QUALIFIER_VALUE)
                          qualifierDebug = "    ^-- #{qualifier} = #{item_PROPERTY_QUALIFIER_VALUE}" 
                        end
                        
                    end

                    puts qualifierDebug if sampleOutput

                end
            end

        end
      end 

    end