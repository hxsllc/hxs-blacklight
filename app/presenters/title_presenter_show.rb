class TitlePresenterShow < Blacklight::ShowPresenter
  def heading
    # Assuming that :main_title and :sub_title are field names on the Solr document.
    if document.first(:holding_institution) then 
      a=document.first(:holding_institution)
    end
    if document.first(:shelfmark) then 
      b=document.first(:shelfmark)
    end
    if document.first(:id) then 
      c=document.first(:id)
    end
    if a && b && c 
      a + ", " + b + " (" + c + ")"
    elsif a && c
      a + " (" + c + ")"
    else
      c
    end
  end
end
