class TitlePresenter < Blacklight::IndexPresenter
  def heading
    # Assuming that :main_title and :sub_title are field names on the Solr document.
    document.first(:holding_institution) + ", " + document.first(:shelfmark) + " (" + document.first(:id_ds) + ")"
  end
end
