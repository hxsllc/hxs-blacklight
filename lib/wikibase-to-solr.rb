## import json functions
require 'json'
require 'csv'
require 'Date'
require 'Time'

##REFACTOR: Add filestream instead of puts
##REFACTOR: Filenames into variables (output, input, etc.) for script config
##REFACTOR: Remove @ (global variables)
##REFACTOR: Nil checking (e.g. MDVN)

#data model // expected data structure
#
#  type=...
#  id=Q...
#  labels=[]
#  descriptions=[]
#  aliases=[]
#  claims=[]
#  .  [Px]=[]
#     .  [mainsnak]=[]
#        .  [snaktype]=...
#        .  [property]=...
#	 .  [datavalue]=[]
#	    .  [value]=...
#	       . [entity-type]=...
#	       . [numeric-id]=...
#	       . [id]=Q...
#     .  [qualifiers]=[]

# KEYS found in each item
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

class String
  def include_any?(array)
    array.any? {|i| self.include? i}
  end
end

def returnMDVNifNotNil (var)
	return var&.dig('mainsnak')&.dig('datavalue')&.dig('value')&.dig('numeric-id')&.to_i
end

def returnMDVifNotNil (var)
	return var&.dig('mainsnak')&.dig('datavalue')&.dig('value')
end

def returnDVifNotNil (var)
	return var&.dig('datavalue')&.dig('value')
end

def returnDVTifNotNil (var)
	return var&.dig('datavalue')&.dig('value')&.dig('time')
end

def returnIDifNotNil (var)
	return var&.dig('id')
end

def returnPropArray0 (var,prop)
	var&.dig(prop)&.first
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
	#value.kind_of?(String) ? str.unicode_normalize: str
	#value.kind_of?(Integer) ? JSON.generate(value): str
end

def directJSONforSolr(id, fieldname, value)
	formatted = formatSolrValue value

	$solrObjects[id] ||= {}
	$solrObjects[id][fieldname] ||= []
	$solrObjects[id][fieldname] << formatted unless $solrObjects[id][fieldname].include? formatted
end

def createJSONforSolr (wid, propertyid, solr_append, fieldname, value)

	# expected solr_append values:
	# => _display (has LD syntax structure, needs to be parsed with Blacklight)
	# => _search (for text search, tokenized)
	# => _facet (for displaying in sidebar facets, not tokenized)
	# => _link (for displaying as a hyperlink)

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
	elsif(fieldname=="")
		# if propertyid=="P18" || propertyid=="P19"
		#	@outputFieldName = "term"
		if $pNameArray.keys.include?(propertyid)
			@outputFieldName = $pNameArray[propertyid]
		else
			@outputFieldName = fieldname
		end
	end

	if checkJSONforSolr(propertyid, solr_append, value)
		directJSONforSolr(wid, "#{@outputFieldName}#{solr_append}", value)
	end
end

def checkJSONforSolr (propertyid, solr_append, value)

	pid = propertyid.tr('P','').to_i

	#v2 displayFieldIDs = [1,5,6,8,10,14,18,19,23,25,29,31,32,34,35]
	#v3
	displayFieldIDs = [1,5,6,8,10,14,20,21,23,26,27,29,30,32,33]

	#v2 searchFieldIDs = [1,5,8,10,14,18,19,23,25,29,32]
	#v3
	searchFieldIDs = [1,4,5,8,10,11,12,13,14,17,20,21,22,23,27,28,29,32]

	#v2 facetFieldIDs = [5,10,14,18,19,23,25,29,32]
	#v3
	facetFieldIDs = [5,10,11,14,20,21,23,25,26,27,31]

	#v2 + v3
	linkFieldIDs = [9,41]

	#v4
	intFieldIDs = [25,36,37]

	if((solr_append=="_display" && displayFieldIDs.include?(pid)) ||
		(solr_append=="_search" && searchFieldIDs.include?(pid)) ||
		(solr_append=="_facet" && facetFieldIDs.include?(pid)) ||
		(solr_append=="_int" && intFieldIDs.include?(pid)) ||
		(solr_append=="_link" && linkFieldIDs.include?(pid))) && value!=""
		return true
	else
		return false
	end

end

def isPropertyJSONOutput (propertyid)

	pid = propertyid.tr('P','').to_i

	displayFieldIDs = [1,5,6,8,10,14,20,21,23,26,27,29,30,32,33]
	searchFieldIDs = [1,4,5,8,10,11,12,13,14,17,20,21,22,23,27,28,29,32]
	facetFieldIDs = [5,10,11,14,20,21,23,25,26,27,31]
	linkFieldIDs = [9,41]
	intFieldIDs = [25,36,37]

	if(displayFieldIDs.include?(pid) ||
		searchFieldIDs.include?(pid) ||
		facetFieldIDs.include?(pid) ||
		intFieldIDs.include?(pid) ||
		linkFieldIDs.include?(pid))
		return true
	else
		return false
	end

end

def mergeWIDs (wid)

	## retrieve ID from item JSON array
	#@wid = mergeWIDs(item.fetch('id'))

	#{
	#"qid_meta": "Q644",
	# => Q644 PP P16 Q2
	#Q644 PP P38 false
	#-- P4 {"entity-type"=>"item", "numeric-id"=>374, "id"=>"Q374"}
	#---- PV University of Pennsylvania QL University of Pennsylvania QU
	#Q644 QQ P5 University of Pennsylvania QL University of Pennsylvania QU
	#Q644 PP P6 Q4
	#Q644 PP P7 9959387343503681
	#Q644 PP P8 Oversize LJS 224
	#Q644 PP P9 https://franklin.library.upenn.edu/catalog/FRANKLIN_9959387343503681
	#},{
	#"qid_meta": "Q645",
	#"id": "DS55",
	#Q645 PP P1 DS55
	# => Q645 PP P16 Q1
	# => Q645 PP P2 Q644
	#},{
	#"qid_meta": "Q646",
	# => Q646 PP P3 Q645
	# => Q646 PP P16 Q3

	@widP2search = $p2array.key(wid)
	if @widP2search.nil?
		@widP3search = $p3array.key(wid)
	else
		@widP3search = $p3array.key(@widP2search)
	end

	if @widP3search.nil?
		return wid
	else
		return @widP3search
	end

end

dir = File.dirname __FILE__
## read file into variable
file = File.read(File.join(dir, '/ds-export-2023-03-02.json'))

## parse JSON into a Ruby array (NOT A HASH!)
data = JSON.parse(file)

## read property names into array = from ds-model-ids.json
$pNameArray={}
CSV.foreach(File.join(dir, "/property-names.csv"), col_sep: ",", liberal_parsing: true) do |line|
	@pName = line[0]
	$pNameArray[@pName] = line[1]
end

# EXAMPLE of "claims" inside authority term objects
#   {"P16"=>[{"mainsnak"=>{"snaktype"=>"value", "property"=>"P16", "datavalue"=>{"value"=>{"entity-type"=>"item", "numeric-id"=>19, "id"=>"Q19"}, "type"=>"wikibase-entityid"}, "datatype"=>"wikibase-item"}, "type"=>"statement", "id"=>"Q20$5B99A94E-7248-442F-8DDC-A2C86E5750DA", "rank"=>"normal"}], "P48"=>[{"mainsnak"=>{"snaktype"=>"value", "property"=>"P48", "datavalue"=>{"value"=>"http://vocab.getty.edu/aat/300264681", "type"=>"string"}, "datatype"=>"url"}, "type"=>"statement", "id"=>"Q20$88B0973B-06CA-44AD-8C38-075FFE217424", "rank"=>"normal"}]}

## LABELS + URIS HASH (ARRAY)
## loop over each top-level object in the JSON data array
## populate translation arrays only when "instance of" P16 >= 4 && <= 19
labels = {}
uris = {}
$p2array = {}
$p3array = {}
outputLabels = false

if true
	# prepare arrays for use in the MAIN LOOP
	data.each do |item|

		# p item

		@wid = ''
		@instance = nil
		@uri = ''
		@label = ''

		## retrieve ID from item HASH array
		@wid = item.fetch('id')

		## retrieve claims from item HASH array
		@claims = JSON.parse item.dig('claims').to_json
		# p @claims
		## try retrieving P16 from claims HASH array, if so populate @instance	     
		@P16 = returnPropArray0 @claims, 'P16'
		# p "P16 #{@P16}"
		@P16 ? @instance = returnMDVNifNotNil(@P16):  nil
		#puts @instance
		#puts "--"
		## try retrieving P46 from claims JSON array, if so populate @uri     
		# v2 @P46 = returnPropArray0 @claims, 'P46'
		# V3
		@P42 = returnPropArray0 @claims, 'P42'
		@P42 ? @uri = "https://www.wikidata.org/wiki/"+returnMDVifNotNil(@P42): nil

		## try retrieving P48 from claims JSON array, if so populate @uri	     
		@P44 = returnPropArray0 @claims, 'P44'
		@P44 ? @uri = returnMDVifNotNil(@P44): nil

		##only populate LABELS HASH with objects matching certain "instance of" [P16] values	
		if @instance.nil? || !@instance.between?(1,3)

			# labels is a top-level property in the exported Wikibase documment
			@labelsArray = JSON.parse(item.dig('labels').to_json)
			@label = returnLabelValue @labelsArray

			#if there is a label present, populate a LABELS array
			@label ? labels[@wid]=@label: nil

			#if there is a URI present, populate a URIs array
			@uri ? uris[@wid]=@uri: nil

			if outputLabels
				puts "---"
				puts @wid
				puts @instance
				puts @label
				puts @uri
			end

			## if the instance_of = 1, 2, 3 then we want to extract the P2 and P3 values into arrays
		elsif @instance.to_i>=1 && @instance.to_i<=3

			@P2 = returnPropArray0 @claims, 'P2'
			@P2 ? $p2array[@wid] = returnIDifNotNil(returnMDVifNotNil(@P2)):  nil
			@P3 = returnPropArray0 @claims, 'P3'
			@P3 ? $p3array[@wid] = returnIDifNotNil(returnMDVifNotNil(@P3)):  nil
		end

	end
end

#verified 02-11-23
#p labels

#p $p2array
#p $p3array


## MAIN LOOP NEW

@debugQualifiers = false
@debugProperties = false
$solrObjects = {}
@outputJSON = true
$globalCnt = 1

if true

	@dataSize = data.count
	@dataLoopCount = 0
	#puts @dataSize

	data.each do |item|

		@dataLoopCount += 1
		@owid = ''
		@wid = ''
		@instance = 0
		@uri = ''
		@label = ''

		## retrieve ID from item JSON array
		@owid = item.fetch('id')
		@wid = mergeWIDs @owid

		## retrieve claims from item JSON array
		@claims = JSON.parse(item.dig('claims').to_json)

		## try retrieving P16 from claims JSON array, if so populate @instance
		@P16 = returnPropArray0(@claims, 'P16')
		@P16 ? @instance = returnMDVNifNotNil(@P16):  nil

		##only process "instance of" [P16] values 1, 2, 3
		if @instance.to_i>=1 && @instance.to_i<=3
      # solrItem['merge'] = "merge: #{@instance} - #{mergeWIDs @owid}"

			#puts "DEBUG: OWID #{@owid} WID #{@wid} LPK #{@lastPropertyKey}"
			directJSONforSolr @wid, "qid_meta", @owid

			@claims.keys.each do |property|

				@propArrayX = returnPropArray(@claims, property)
				@propArrayTotal = @propArrayX.length
				@propArrayLoopCount = 0
				@propArrayX.each do |propArray|
					@propArrayLoopCount += 1
					propArray ? @propValue = returnMDVifNotNil(propArray): nil

					#custom properties that are not part of property-names.csv
					directJSONforSolr @wid, "id", @propValue if property=="P1" && !@propValue.empty?
					directJSONforSolr(@wid, "images_facet", "Yes") if property == 'P41' && !@propValue.empty?

					#check for mainsnak-datavalue-value that looks like {"entity-type"=>"item", "numeric-id"=>1102, "id"=>"Q1102"}
					#P26 example = {"entity-type":"item","numeric-id":14,"id":"Q14"}
					if @propValue.kind_of?(Hash)
						@propID = returnIDifNotNil(@propValue)
						@propValue = labels[@propID]
					end

					propArray ? @qualifiers = returnPropQuals(propArray): nil

					if @propArrayLoopCount==@propArrayTotal
						@lastPropertyValue=true
					else
						@lastPropertyValue=false
					end

					if @qualifiers

						#set initial state of holding variables
						@qualID = ''
						@qualLabel = ''
						@qualURI = ''
						@qualAGR = ''
						@qualRole = ''
						@qualAuth = ''
						@qualDate = ''
						@qualCentury = ''
						@qualLatest = ''
						@qualEarliest = ''
						@qualMaterial = ''

						@qualifiers.keys.each do |qual|
							
							@qualArray = returnPropArray0(@qualifiers, qual)
							#@qualValue = returnDVifNotNil(@qualArray)
							qual.include_any?(['P25','P36','P37']) ? @qualValue = returnDVTifNotNil(@qualArray): @qualValue = returnDVifNotNil(@qualArray)

							if @qualValue.kind_of?(Hash)
								@qualID = returnIDifNotNil(@qualValue)
								@qualID ? @qualLabel = labels[@qualID]: nil
								@qualID ? @qualURI = uris[@qualID]: nil
							end

							# most properties only have one qualifier, but P14 has 1-3 qualifiers
							# so you have to extract them from the loop

							#P10 contains qualifiers P13, P15, and P17 (agr, role, auth)
							qual=='P13' ? @qualAGR = @qualValue: nil
							qual=='P15' ? @qualRole = @qualLabel: nil
							qual=='P17' ? @qualAuth = @qualLabel: nil

							#P23 contains qualifiers P24, P25, P36, P37
							qual=='P24' ? @qualDate = @qualValue: nil
							qual=='P25' ? @qualCentury = @qualValue: nil 
							qual=='P36' ? @qualLatest = @qualValue: nil 
							qual=='P37' ? @qualEarliest = @qualValue: nil 

							#P30 contains qualifiers P31
							qual=='P31' ? @qualMaterial = @qualValue: nil

							if @debugQualifiers
								puts "#{@wid} QQ #{property} >> has qualifiers"
								puts "-- #{qual} #{@qualValue}"
								puts "---- PV #{@propValue} QL #{@qualLabel} QU #{@qualURI}"
							end

							#end of @qualifiers loop
						end

						if property=='P14'
							#special data format output rules for P14 (associated name)
							#P14 is the only property-qualifier that might contain AGR (P13)
							#P14 is the only property in which the field name gets modified to the ROLE (P15)	
													
							if @qualAGR.empty? && @qualAuth.empty?
								createJSONforSolr(@wid, property, "_display", @qualRole,  { "PV": @propValue })
								createJSONforSolr(@wid, property, "_search", @qualRole, @propValue)
								createJSONforSolr(@wid, property, "_facet", @qualRole, @propValue)
							elsif @qualAGR && @qualAuth.empty?
								createJSONforSolr(@wid, property, "_display", @qualRole, { "PV": @propValue, "AGR": @qualAGR })
								createJSONforSolr(@wid, property, "_search", @qualRole, @propValue)
								createJSONforSolr(@wid, property, "_search", @qualRole, @qualAGR)
								createJSONforSolr(@wid, property, "_facet", @qualRole, @propValue)
							elsif @qualAGR.empty? && @qualAuth
								createJSONforSolr(@wid, property, "_display", @qualRole, { "PV": @propValue, "QL": @qualAuth, "QU": @qualURI })
								createJSONforSolr(@wid, property, "_search", @qualRole, @propValue)
								createJSONforSolr(@wid, property, "_search", @qualRole, @qualAuth)
								createJSONforSolr(@wid, property, "_facet", @qualRole, @qualAuth)
							else #@qualAGR && @qualAuth then
								createJSONforSolr(@wid, property, "_display", @qualRole, { "PV": @propValue, "AGR": @qualAGR, "QL": @qualAuth, "QU": @qualURI })
								createJSONforSolr(@wid, property, "_search", @qualRole, @propValue)
								createJSONforSolr(@wid, property, "_search", @qualRole, @qualAGR)
								createJSONforSolr(@wid, property, "_search", @qualRole, @qualAuth)
								createJSONforSolr(@wid, property, "_facet", @qualRole, @qualAuth)
							end
						elsif property=='P23'
							#special data format output rules for P23 (date)
							# - P24 century_authority
							# - P25 century (UTC format)
							# - P37 earliest date (UTC format)
							# - P36 latest date (UTC format)

							if @debugProperties then puts "#{@wid} QQ #{property} #{@propValue} QL #{@qualLabel} QU #{@qualURI}" end
							createJSONforSolr(@wid, property, "_display", "", { "PV": @propValue, "QL": @qualLabel, "QU": @qualURI })
              createJSONforSolr(@wid, property, "_search", "", @propValue)
							createJSONforSolr(@wid, property, "_search", "", @qualLabel)
							createJSONforSolr(@wid, property, "_facet", "", @qualLabel)
							createJSONforSolr(@wid, 'P25', "_int", "", Time.parse(@qualCentury).year)
							createJSONforSolr(@wid, 'P37', "_int", "", Time.parse(@qualEarliest).year)
							createJSONforSolr(@wid, 'P36', "_int", "", Time.parse(@qualLatest).year)
							createJSONforSolr(@wid, 'P25', "_facet", "", Time.parse(@qualCentury).year.to_s)
						elsif property=='P30'
							#if @debugProperties then puts "#{@wid} QQ #{property} #{@propValue} QL #{@qualLabel} QU #{@qualURI}" end
							if @debugProperties then puts "P31 material_facet #{@qualMaterial} #{@qualLabel}" end
							createJSONforSolr(@wid, 'P31', "_facet", "", @qualLabel)
            else
							if @debugProperties then puts "#{@wid} QQ #{property} #{@propValue} QL #{@qualLabel} QU #{@qualURI}" end

              createJSONforSolr(@wid, property, "_display", "", { "PV": @propValue, "QL": @qualLabel, "QU": @qualURI })
							createJSONforSolr(@wid, property, "_search", "", @propValue)
							createJSONforSolr(@wid, property, "_search", "", @qualLabel)
							createJSONforSolr(@wid, property, "_facet", "", @qualLabel)
						end

						#reset state of holding variables
						@qualID = ''
						@qualLabel = ''
						@qualURI = ''
						@qualAGR = ''
						@qualRole = ''
						@qualAuth = ''

						#else if no @qualifiers exist
          else

						if @debugProperties then puts "#{@wid} PP #{property} #{@propValue}" end

						@propValueExport = @propValue.to_json

						createJSONforSolr(@wid, property, "_display", @qualRole, "{\"PV\": #{@propValueExport}}")
						createJSONforSolr(@wid, property, "_search", "", @propValue)
						createJSONforSolr(@wid, property, "_facet", "", @propValue)
						createJSONforSolr(@wid, property, "_link", "", @propValue)
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

	#end if true
end

puts JSON.pretty_generate($solrObjects.values) if @outputJSON
