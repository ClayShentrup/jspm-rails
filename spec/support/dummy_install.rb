# frozen_string_literal: true

require 'open3'

# Runs `rails jspm:install` in the dummy app once per suite, the way a
# developer would, and keeps what it printed.
module DummyInstall
  DIRECTORY = File.expand_path('../dummy', __dir__)
  public_constant :DIRECTORY

  class << self
    def output
      @output ||= run
    end

    private

    def run
      output, status = Open3.capture2e('bin/rails', 'jspm:install', chdir: DIRECTORY)
      abort(output) unless status.success?
      output
    end
  end
end
