# frozen_string_literal: true

module Jspm
  # View helpers for apps whose JavaScript jspm-rails installs.
  module Helper
    def javascript_jspm_tags
      Tags.call(view: self)
    end
  end
end
