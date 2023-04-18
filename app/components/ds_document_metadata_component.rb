# frozen_string_literal: true

# Document metadata view component
#
# Overrides the blacklight implementation so each field can be displayed using the DsMetadataFieldComponent and not
# the builtin blacklight MetadataFieldComponent.
class DsDocumentMetadataComponent < Blacklight::DocumentMetadataComponent
  def initialize(fields: [], show: false)
    @fields_with_keys = fields.index_by { |field| field.key.to_sym }
    super
  end

  def field_component(_field)
    DsMetadataFieldComponent
  end
end
