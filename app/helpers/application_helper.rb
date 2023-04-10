# Application view helper methods
module ApplicationHelper
  LINK_DATA_DEFAULT = :other
  LINK_DATA_ACRONYMS = {
    wikidata: {
      domain: 'wikidata.org'
    },
    tgn: {
      host: 'vocab.getty.edu',
      path: /^\/tgn\//i
    },
    aat: {
      host: 'vocab.getty.edu',
      path: /^\/aat\//i
    },
  }.freeze

  # rubocop:disable Lint/UnusedMethodArgument
  #  Blacklight requires the named arguments
  def make_link document:, field:, value:, context:, config:
    safe_join(Array(value).map do |v|
        link_to(v, v)
      end, ',')
  end
  # rubocop:enable Lint/UnusedMethodArgument

  # rubocop:disable Lint/UnusedMethodArgument
  #  Blacklight requires the named arguments
  def make_btn_iiif document:, field:, value:, context:, config:
    safe_join(Array(value).map do |v|
        link_to("IIIF Manifest", v, class: 'btn btn-secondary')
      end, ',')
  end
  # rubocop:enable Lint/UnusedMethodArgument

  # rubocop:disable Lint/UnusedMethodArgument
  #  Blacklight requires the named arguments
  def make_btn_inst document:, field:, value:, context:, config:
    safe_join(Array(value).map do |v|
        link_to("Institutional Record", v, class: 'btn btn-secondary')
      end, ',')
  end
  # rubocop:enable Lint/UnusedMethodArgument

  # rubocop:disable Lint/UnusedMethodArgument
  #  Blacklight requires the named arguments
  def link_with_copy document:, field:, value:, context:, config:
    values = value.map do |v|
      render partial: 'shared/link_with_icon',
             locals: { document: document, field: field, value: v, context: context, config: config }
    end

    safe_join values, "\n"
  end
  # rubocop:enable Lint/UnusedMethodArgument

  def century_label(value)
    case value
    when "801"
      "9th century"
    when "901"
      "10th century"
    when "1001"
      "11th century"
    when "1101"
      "12th century"
    when "1201"
      "13th century"
    when "1301"
      "14th century"
    when "1401"
      "15th century"
    when "1501"
      "16th century"
    when "1601"
      "17th century"
    when "1701"
      "18th century"
    else
      value
    end
  end

  #V2.0 TEXT ONLY
  # rubocop:disable Lint/UnusedMethodArgument
  #  Blacklight requires the named arguments
  def property_value document:, field:, value:, context:, config:
    values =  Array(value).map do |json_string|
      data = JSON.parse json_string
      data['PV'].html_safe
    end

    safe_join values, '<br />'.html_safe
  end
  # rubocop:enable Lint/UnusedMethodArgument

  # rubocop:disable Lint/UnusedMethodArgument
  #  Blacklight requires the named arguments
  def search_term_link document:, field:, value:, context:, config:, facet_field: nil
    facet_field ||= generate_search_facet_field field
    links = Array(value).map { |term| search_term_item term, field, facet_field  }
    safe_join links, "\n"
  end
  # rubocop:enable Lint/UnusedMethodArgument

  #V2.0 VISUAL BAR, NO LINKED DATA
  # rubocop:disable Lint/UnusedMethodArgument
  #  Blacklight requires the named arguments
  def search_link document:, field:, value:, context:, config:, facet_field: nil
    facet_field ||= generate_search_facet_field field
    links = Array(value).map { |json_string| search_link_item json_string, field, facet_field  }
    safe_join links, "\n"
  end
  # rubocop:enable Lint/UnusedMethodArgument

  #V3.1 Linked Data bar with placeholder grayscale icon and #AUTH# hyperlink + AGR value
  # rubocop:disable Lint/UnusedMethodArgument
  #  Blacklight requires the named arguments
  def search_data_link document:, field:, value:, context:, config:, facet_field: nil
    facet_field ||= generate_search_facet_field field
    links = Array(value).map { |json_string| search_data_link_item json_string, field, facet_field  }
    safe_join links, "\n"
  end
  # rubocop:enable Lint/UnusedMethodArgument

  private

  def generate_search_facet_field(field)
    "#{field.to_s.split('_')[0...-1].join('_')}_facet"
  end

  def search_term_item(term, field, facet_field)
    return if term.blank?

    render partial: 'shared/search_link',
           locals: { field: field, facet_field: facet_field, term: term }
  end

  def search_link_item(json_string, field, facet_field)
    data = JSON.parse json_string
    return if data['QL'].blank?

    render partial: 'shared/search_link',
           locals: { field: field, facet_field: facet_field, term: data['QL'] }
  end

  def search_data_link_item(json_string, field, facet_field)
    data = JSON.parse json_string
    label = data['AGR'].present? ? "#{data['PV']} / #{data['AGR']}" : data['PV']
    render partial: 'shared/search_data_link',
           locals: {
             field: field,
             facet_field: facet_field,
             label: label,
             term: data['QL'],
             source: data['QU'],
             source_acronym: find_url_acronym(data['QU'])
           }
  end

  def find_url_acronym(url, default: LINK_DATA_DEFAULT)
    return nil if url.blank?

    uri = Addressable::URI.parse url
    LINK_DATA_ACRONYMS.keys.find(-> { default }) { |key| url_acronym_match? uri, LINK_DATA_ACRONYMS[key] }
  end

  def url_acronym_match?(uri, acronym)
    acronym.all? do |part, test|
      case test
      when Regexp
        uri.send(part).match? test
      else
        uri.send(part) === test
      end
    end
  end
end
