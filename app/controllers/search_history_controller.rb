# frozen_string_literal: true

# Blacklight enabled user search history
class SearchHistoryController < ApplicationController
  include Blacklight::SearchHistory
  helper BlacklightRangeLimit::ViewHelperOverride
  helper RangeLimitHelper

  helper BlacklightAdvancedSearch::RenderConstraintsOverride
end
