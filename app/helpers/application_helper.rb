module ApplicationHelper
  def make_link document:, field:, value:, context:, config:
	safe_join(Array(value).map do |v|
      link_to(v, v)
    end, ',')
  end
end
