# frozen_string_literal: true

# Overrides the default Blacklight title presenter for the catalog index action
class TitlePresenterIndex < Blacklight::IndexPresenter
  def heading
    # Assuming that :main_title and :sub_title are field names on the Solr document.
    a = document.first(:institution_facet) if document.first(:institution_facet)
    b = document.first(:shelfmark_search) if document.first(:shelfmark_search)
    return unless a && b

    "#{a}, #{b}"
  end
end
