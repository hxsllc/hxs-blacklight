## import functions
require 'json'
require 'csv'
require 'date'
require 'time'
require 'optparse'


# SOLR dynamic fields
# => _display (has LD syntax structure, needs to be parsed with Blacklight)
# => _search (for text search, tokenized)
# => _facet (for displaying in sidebar facets, not tokenized)
# => _link (for displaying as a hyperlink)
# => _int (for dates)
# => _meta (for plain text data)

## field output configuration, i.e. 
# => @displayFieldIDs = YES to output _display for that property
# => @searchFieldIDs = YES to output _search for that property

	@displayFieldIDs = [1,5,6,8,10,14,18,21,23,26,27,29,30,32,33].freeze
	@searchFieldIDs = [1,4,5,8,10,11,12,13,14,17,18,21,22,23,27,28,29,32].freeze
	@facetFieldIDs = [5,10,11,14,18,21,23,25,26,27,31].freeze
	@linkFieldIDs = [9,41].freeze
	@intFieldIDs = [25,36,37].freeze

## general configuration

	dir = File.dirname __FILE__
	importJSONfile = File.expand_path 'export.json', dir
	outputJSONFile = File.expand_path 'import.json', dir
	importPropertyFile = File.expand_path 'property-names.csv', dir

## parameter definition

OptionParser.new do |opts|
  opts.banner = 'Usage: wikibase-to-solr.rb [options]'

  opts.on('-i', '--wiki-export=FILE', 'The file path to the Wikibase JSON export file.') do |f|
    importJSONfile = File.expand_path f, dir
  end

  opts.on('-o', '--output=FILE', 'The file path to output the formatted Solr JSON file.') do |f|
    outputJSONFile = File.expand_path f, dir
  end

  opts.on('-v', '--verbose', 'Verbose logging') do |v|
    debugProperties = true
    debugLabels = true
    debugQualifiers = true
  end
end.parse!

## custom functions for data processing of the Wikibase JSON array

		class String
		  def include_any?(array)
		    array.any? {|i| self.include? i}
		  end
		end

		# return XXX in {"mainsnak"=>"datavalue"=>{"value"=>{"numeric-id"="XXX"}}}
		def returnMDVNifNotNil (var)
			return var&.dig('mainsnak')&.dig('datavalue')&.dig('value')&.dig('numeric-id')&.to_i
		end

		# return XXX in {"mainsnak"=>"datavalue"=>{"value"=>"XXX"}}
		def returnMDVifNotNil (var)
			return var&.dig('mainsnak')&.dig('datavalue')&.dig('value')
		end

		# return XXX in {"datavalue"=>{"value"=>"XXX"}}
		def returnDVifNotNil (var)
			return var&.dig('datavalue')&.dig('value')
		end

		# return XXX in {"datavalue"=>{"value"=>{"time"=>"XXX"}}
		def returnDVTifNotNil (var)
			return var&.dig('datavalue')&.dig('value')&.dig('time')
		end

		def returnIDifNotNil (var)
			return var&.dig('id')
		end

		def returnPropArrayFirst (var,prop)
			if var
			unless var.empty?
			  var&.dig(prop)&.first
			end
			end
		end

		def returnPropArray (var,prop)
			return var&.dig(prop)
		end

		def returnPropQuals (var)
			return var&.dig('qualifiers')
		end

		def returnLabelValue (var)
			return var&.dig('en')&.dig('value')
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

		def createJSONforSolr (wikibaseid, propertyid, solr_append, fieldname, value)

			pid = propertyid.tr('P','').to_i

			# special cases for field names
			if(fieldname=="Scribe")
				@outputFieldName = "scribe"
			elsif(fieldname=="Author")
				@outputFieldName = "author"
			elsif(fieldname=="Former owner")
				@outputFieldName = "owner"
			elsif(fieldname=="Artist")
				@outputFieldName = "artist"
			elsif(fieldname=="Associated agent")
				@outputFieldName = "agent"
			elsif(fieldname=="")
				if $propertyNameArray.keys.include?(propertyid)
					@outputFieldName = $propertyNameArray[propertyid]
				else
					@outputFieldName = fieldname
				end
			end

		  #check if the property should be output for the specified _append
			if isPropertyJSONOutput(propertyid, solr_append, value)

				#generate JSON - "fieldname_append": "value"
				generateJSONforSolr(wikibaseid, "#{@outputFieldName}#{solr_append}", value)

			end
		end

		def isPropertyJSONOutput (propertyid, solr_append, value)

			pid = propertyid.tr('P','').to_i

			if((solr_append=="_display" && @displayFieldIDs.include?(pid)) ||
				(solr_append=="_search" && @searchFieldIDs.include?(pid)) ||
				(solr_append=="_facet" && @facetFieldIDs.include?(pid)) ||
				(solr_append=="_int" && @intFieldIDs.include?(pid)) ||
				(solr_append=="_link" && @linkFieldIDs.include?(pid))) && value!=""
				return true
			else
				return false
			end

		end

		def mergeWIDs (wikibaseid)

			## retrieve ID from item JSON array
			#@wid = mergeWIDs(item.fetch('id'))

			@widP2search = $p2Records.key(wikibaseid)
			if @widP2search.nil?
				@widP3search = $p3Records.key(wikibaseid)
			else
				@widP3search = $p3Records.key(@widP2search)
			end

			if @widP3search.nil?
				return wikibaseid
			else
				return @widP3search
			end

		end

## load JSON into a Ruby array
data = JSON.load_file importJSONfile

## read property names into array < from property-names.csv

$propertyNameArray={}
CSV.foreach(importPropertyFile, col_sep: ",", liberal_parsing: true) do |line|
	@propertyName = line[0]
	$propertyNameArray[@propertyName] = line[1]
end

## lookup arrays LOOP:
##   loop over each Wikibase object in the JSON data array
##   populate labels and URIs array only when "instance of" P16 >= 4 && <= 19

labels = {}
uris = {}
$p2Records = {}
$p3Records = {}

data.each do |item|

	@uri = ''
	@label = ''

	## retrieve ID from item HASH array
	item_WIKIBASE_ID = item.fetch('id')
	## retrieve claims from item HASH array
	item_CLAIMS = JSON.parse item.dig('claims').to_json

	## try retrieving P16 (INSTACE_OF) from claims HASH array, if so populate @instance	     
	item_INSTANCE_OF = returnPropArrayFirst item_CLAIMS, 'P16'

	# if P16 is populated, get the instance

	item_INSTANCE_OF ? item_INSTANCE_OF = returnMDVNifNotNil(item_INSTANCE_OF):  nil

	## try retrieving P42 from claims JSON array, if so populate @uri     
	item_WIKIDATA_QID = returnPropArrayFirst item_CLAIMS, 'P42'
	item_WIKIDATA_QID ? @uri = "https://www.wikidata.org/wiki/"+returnMDVifNotNil(item_WIKIDATA_QID): nil

	## try retrieving P48 from claims JSON array, if so populate @uri	     
	item_EXTERNAL_URI = returnPropArrayFirst @claims, 'P44'
	item_EXTERNAL_URI ? @uri = returnMDVifNotNil(item_EXTERNAL_URI): nil

	##only populate LABELS HASH with objects matching certain "instance of" [P16] values	
	if item_INSTANCE_OF.nil? || !item_INSTANCE_OF.between?(1,3)

		# labels is a top-level property in the exported Wikibase documment
		@labelsArray = JSON.parse(item.dig('labels').to_json)
		@label = returnLabelValue @labelsArray

		#if there is a label present, populate a LABELS array
		@label ? labels[item_WIKIBASE_ID]=@label: nil

		#if there is a URI present, populate a URIs array
		@uri ? uris[item_WIKIBASE_ID]=@uri: nil

		## if the instance_of = 1, 2, 3 then we want to extract the P2 and P3 values into arrays
	elsif item_INSTANCE_OF.to_i>=1 && item_INSTANCE_OF.to_i<=3

		@P2 = returnPropArrayFirst item_CLAIMS, 'P2'
		@P2 ? $p2Records[item_WIKIBASE_ID] = returnIDifNotNil(returnMDVifNotNil(@P2)):  nil
		@P3 = returnPropArrayFirst item_CLAIMS, 'P3'
		@P3 ? $p3Records[item_WIKIBASE_ID] = returnIDifNotNil(returnMDVifNotNil(@P3)):  nil
	end

end

## main LOOP:
##   loop over each Wikibase object in the JSON data array
##   evaluate when "instance of" P16 >= 1 && <= 3

$solrObjects = {}

data.each do |item|

	#p item
	@owid = ''
	@wikibaseid = ''
	@instance = 0
	@uri = ''
	@label = ''

	## retrieve ID from item JSON array
	@owid = item.fetch('id')
	#p @owid
	@wikibaseid = mergeWIDs @owid

	## retrieve claims from item JSON array
	@claims = JSON.parse(item.dig('claims').to_json)

	## try retrieving P16 from claims JSON array, if so populate @instance
	item_INSTANCE_OF = returnPropArrayFirst(@claims, 'P16')
	item_INSTANCE_OF ? @instance = returnMDVNifNotNil(item_INSTANCE_OF):  nil

	##only process "instance of" [P16] values 1, 2, 3
	if @instance.to_i>=1 && @instance.to_i<=3

		generateJSONforSolr @wikibaseid, "qid_meta", @owid

		@claims.keys.each do |property|

			@propArrayX = returnPropArray(@claims, property)
			@propArrayTotal = @propArrayX.length
			@propArrayLoopCount = 0
			@propArrayX.each do |propArray|
				propArray ? @propValue = returnMDVifNotNil(propArray): nil

				#custom properties that are not part of property-names.csv
				generateJSONforSolr @wikibaseid, "id", @propValue if property=="P1" && !@propValue.empty?
				generateJSONforSolr(@wikibaseid, "images_facet", "Yes") if property == 'P41' && !@propValue.empty?

				#check for MDV (mainsnak-datavalue-value) that looks like
				#P26 example = {"entity-type":"item","numeric-id":14,"id":"Q14"}
				if @propValue.kind_of?(Hash)
					#get "id" = "Q14"
					@propID = returnIDifNotNil(@propValue)
					#translate "Q14" to its label
					@propValue = labels[@propID]
				end

				propArray ? @qualifiers = returnPropQuals(propArray): nil

				if @qualifiers

					#set initial state of holding variables
					@qualID = ''
					@qualLabel = ''
					@qualURI = ''
					@qualAGR = ''
					@qualRole = ''
					@qualAuth = Array.new
					@qualDate = ''
					@qualCentury = ''
					@qualLatest = ''
					@qualEarliest = ''
					@qualMaterial = ''

					@qualifiers.keys.each do |qualPropertyId|
						
						@qualArray = returnPropArrayFirst(@qualifiers, qualPropertyId)
						#if P25, P36, P37 then return datavalue-value-time, otherwise return datavalue-value
						qualPropertyId.include_any?(['P25','P36','P37']) ? @qualValue = returnDVTifNotNil(@qualArray): @qualValue = returnDVifNotNil(@qualArray)

						#check for MDV (mainsnak-datavalue-value) that looks like
						#P26 example = {"entity-type":"item","numeric-id":14,"id":"Q14"}
						if @qualValue.kind_of?(Hash)
							@qualID = returnIDifNotNil(@qualValue)
							@qualID ? @qualLabel = labels[@qualID]: nil
							@qualID ? @qualURI = uris[@qualID]: nil
						end

						#P10 contains qualifiers P13, P15, and P17 (agr, role, authority)
						qualPropertyId=='P13' ? @qualAGR = @qualValue: nil
						qualPropertyId=='P15' ? @qualRole = @qualLabel: nil

            ##there can be multiple P17s inside P10 qualifiers
            ##there can be multiple name authorities inside an associated name
						if qualPropertyId === 'P17'
              @qualAuth += @qualifiers[qualPropertyId].map do |qualifier|
                data = returnDVifNotNil qualifier
                id = returnIDifNotNil data
                labels[id]
              end
            end

						# P23 (..) contains qualifiers 
						# => P24 (name_authority)
						# => P25 (..)
						# => P36 (..) 
						# => P37 (..)
						qualPropertyId=='P24' ? @qualDate = @qualValue: nil
						qualPropertyId=='P25' ? @qualCentury = @qualValue: nil 
						qualPropertyId=='P36' ? @qualLatest = @qualValue: nil 
						qualPropertyId=='P37' ? @qualEarliest = @qualValue: nil 

						#P30 contains qualifier P31
						qualPropertyId=='P31' ? @qualMaterial = @qualValue: nil

						#end of @qualifiers loop
					end

					# most properties only have one qualifier, but P14 has 0, 1, 2, or 3 qualifiers
					# so you have to extract them from the loop
					if property=='P14'

						#special data format output rules for P14 (associated name)
						#P14 is the only property-qualifier that might contain AGR (P13)
						#P14 is the only property in which the field name gets modified to the ROLE (P15)	
												
						if @qualAGR.empty? && @qualAuth.empty?
							#when AGR and Authority are empty, we only output the Recorded Name
							createJSONforSolr(@wikibaseid, property, "_display", @qualRole,  { "PV": @propValue })
							createJSONforSolr(@wikibaseid, property, "_search", @qualRole, @propValue)
							createJSONforSolr(@wikibaseid, property, "_facet", @qualRole, @propValue)
						elsif @qualAGR && @qualAuth.empty?
							#when AGR is present but Name Authority is empty, we output the AGR + Recorded Name 
							createJSONforSolr(@wikibaseid, property, "_display", @qualRole, { "PV": @propValue, "AGR": @qualAGR })
							createJSONforSolr(@wikibaseid, property, "_search", @qualRole, @propValue)
							createJSONforSolr(@wikibaseid, property, "_search", @qualRole, @qualAGR)
							createJSONforSolr(@wikibaseid, property, "_facet", @qualRole, @propValue)
						elsif @qualAGR.empty? && @qualAuth
							#when AGR is empty (normal) and Name Authority is present, we output the Recorded Name + Name Authority (Label + URI)
							@qualAuth.each do |nameAuthority|
								createJSONforSolr(@wikibaseid, property, "_display", @qualRole, { "PV": @propValue, "QL": nameAuthority, "QU": @qualURI })
								createJSONforSolr(@wikibaseid, property, "_search", @qualRole, @propValue)
								createJSONforSolr(@wikibaseid, property, "_search", @qualRole, nameAuthority)
								createJSONforSolr(@wikibaseid, property, "_facet", @qualRole, nameAuthority)
							end
						else #@qualAGR && @qualAuth then
							#when AGR is present and Name Authority is present, we output the AGR + Recorded Name + Name Authority (Label + URI)
							@qualAuth.each do |nameAuthority|
								createJSONforSolr(@wikibaseid, property, "_display", @qualRole, { "PV": @propValue, "AGR": @qualAGR, "QL": nameAuthority, "QU": @qualURI })
								createJSONforSolr(@wikibaseid, property, "_search", @qualRole, @propValue)
								createJSONforSolr(@wikibaseid, property, "_search", @qualRole, @qualAGR)
								createJSONforSolr(@wikibaseid, property, "_search", @qualRole, nameAuthority)
								createJSONforSolr(@wikibaseid, property, "_facet", @qualRole, nameAuthority)
							end
						end
					elsif property=='P23'
						#special data format output rules for P23 (date)
						# - P24 century_authority
						# - P25 century (UTC format)
						# - P37 earliest date (UTC format)
						# - P36 latest date (UTC format)

						if property=='P23' then generateJSONforSolr @wikibaseid, "date_meta", @propValue end
						createJSONforSolr(@wikibaseid, property, "_display", "", { "PV": @propValue, "QL": @qualLabel, "QU": @qualURI })
            createJSONforSolr(@wikibaseid, property, "_search", "", @propValue)
						createJSONforSolr(@wikibaseid, property, "_search", "", @qualLabel)
						createJSONforSolr(@wikibaseid, property, "_facet", "", @qualLabel)

						# generate _int values for Century, Earliest, and Latest, and a string version of Century for the date range facet
						createJSONforSolr(@wikibaseid, 'P25', "_int", "", Time.parse(@qualCentury).year)
						createJSONforSolr(@wikibaseid, 'P37', "_int", "", Time.parse(@qualEarliest).year)
						createJSONforSolr(@wikibaseid, 'P36', "_int", "", Time.parse(@qualLatest).year)

					elsif property=='P30'
						#if @debugProperties then puts "#{@wikibaseid} QQ #{property} #{@propValue} QL #{@qualLabel} QU #{@qualURI}" end
						createJSONforSolr(@wikibaseid, 'P31', "_facet", "", @qualLabel)

          else
            createJSONforSolr(@wikibaseid, property, "_display", "", { "PV": @propValue, "QL": @qualLabel, "QU": @qualURI })
						createJSONforSolr(@wikibaseid, property, "_search", "", @propValue)
						createJSONforSolr(@wikibaseid, property, "_search", "", @qualLabel)
						createJSONforSolr(@wikibaseid, property, "_facet", "", @qualLabel)

					end

				#else if no @qualifiers exist
        else

					@propValueExport = @propValue.to_json

					createJSONforSolr(@wikibaseid, property, "_display", @qualRole, "{\"PV\": #{@propValueExport}}")
					createJSONforSolr(@wikibaseid, property, "_search", "", @propValue)
					createJSONforSolr(@wikibaseid, property, "_facet", "", @propValue)
					createJSONforSolr(@wikibaseid, property, "_link", "", @propValue)

				#end if @qualifiers
        end

			#end @propArrayX.each loop
			end

		#end @claims.keys.each loop
		end

	#end if instance_of = 3
	end

#end data loop
end


# output JSON to stdout
# here is where you could implement output batching
File.write outputJSONFile, JSON.pretty_generate($solrObjects.values)
