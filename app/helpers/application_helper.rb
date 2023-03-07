module ApplicationHelper
	
  def make_link document:, field:, value:, context:, config:
	safe_join(Array(value).map do |v|
      link_to(v, v)
    end, ',')
  end
  
  def make_btn_iiif document:, field:, value:, context:, config:
	safe_join(Array(value).map do |v|
      link_to("IIIF Manifest", v, class: 'btn btn-secondary')
    end, ',')
  end
  
  def make_btn_inst document:, field:, value:, context:, config:
	safe_join(Array(value).map do |v|
      link_to("Institutional Record", v, class: 'btn btn-secondary')
    end, ',')
  end  

  def link_with_copy document:, field:, value:, context:, config:
    values = value.map do |v|
      render partial: 'shared/link_with_icon',
             locals: { document: document, field: field, value: v, context: context, config: config }
    end

    safe_join values, "\n"
  end
end
