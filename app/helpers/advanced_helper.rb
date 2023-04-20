# frozen_string_literal: true

# Helper methods for the advanced search form
module AdvancedHelper
  # Fill in default from existing search, if present
  # -- if you are using same search fields for basic
  # search and advanced, will even fill in properly if existing
  # search used basic search on same field present in advanced.
  def label_tag_default_for(key)
    if params[key].present?
      params[key]
    elsif params['search_field'] == key || guided_context(key)
      params['q']
    end
  end

  # Is facet value in adv facet search results?
  def facet_value_checked?(field, value)
    BlacklightAdvancedSearch::QueryParser.new(params, blacklight_config).filters_include_value?(field, value)
  end

  # Current params without fields that will be over-written by adv. search,
  # or other fields we don't want.
  def advanced_search_context
    my_params = params.except :page, :commit, :f_inclusive, :q, :search_field, :op, :action, :index, :sort,
                              :controller, :utf8

    my_params.except(*search_fields_for_advanced_search.map { |_key, field_def| field_def[:key] })
  end

  def search_fields_for_advanced_search
    @search_fields_for_advanced_search ||= blacklight_config.search_fields.select do |_k, v|
      v.include_in_advanced_search || v.include_in_advanced_search.nil?
    end
  end

  # Use configured facet partial name for facet or fallback on 'catalog/facet_limit'
  def advanced_search_facet_partial_name(display_facet)
    facet_configuration_for_field(display_facet.name).try(:partial) || 'catalog/facet_limit'
  end

  def advanced_key_value
    key_value = []
    search_fields_for_advanced_search.each do |field|
      key_value << [field[1][:label], field[0]]
    end
    key_value
  end

  # carries over original search field and original guided search fields if user switches to guided search from regular search
  def guided_field(field_num, default_val)
    if field_num == :f1 && params[:f1].nil? && params[:f2].nil? && params[:f3].nil? && params[:search_field] && search_fields_for_advanced_search[params[:search_field]]
      return search_fields_for_advanced_search[params[:search_field]].key || default_val
    end

    params[field_num] || default_val
  end

  # carries over original search query if user switches to guided search from regular search
  def guided_context(key)
    key == :q1 && params[:f1].nil? && params[:f2].nil? && params[:f3].nil? &&
      params[:search_field] && search_fields_for_advanced_search[params[:search_field]]
  end

  # carries over guided search operations if user switches back to guided search from regular search
  def guided_radio(op_num, op)
    if params[op_num]
      params[op_num] == op
    else
      op == 'AND'
    end
  end
end
