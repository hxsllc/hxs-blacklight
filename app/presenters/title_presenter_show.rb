class TitlePresenterShow < Blacklight::ShowPresenter
  def heading
    # Assuming that :main_title and :sub_title are field names on the Solr document.
    if document.first(:institution_facet) then 
      a=document.first(:institution_facet)
    end
    if document.first(:shelfmark_search) then 
      b=document.first(:shelfmark_search)
    end
    if a && b
      a + ", " + b
    end
  end
end
