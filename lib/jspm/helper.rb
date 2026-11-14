# frozen_string_literal: true

module Jspm
  # View helpers for apps whose JavaScript jspm-rails installs.
  module Helper
    def javascript_jspm_tags
      javascript_jspm_entry_tags('application')
    end

    # Loads app/javascript/<entry>.js instead of application.js, for a layout
    # whose pages need different code.
    def javascript_jspm_entry_tags(entry)
      Tags.call(entry:, view: self)
    end
  end
end
