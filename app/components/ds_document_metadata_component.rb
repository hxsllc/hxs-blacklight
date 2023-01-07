class DsDocumentMetadataComponent < Blacklight::DocumentMetadataComponent 
    
    def initialize(fields: [], show: false)
	  @fields_with_keys = fields.each_with_object({}) { |field, hash| hash[field.key.to_sym] = field }
	  super
	end
    
    def field_component(field)
      DsMetadataFieldComponent
    end
    
end