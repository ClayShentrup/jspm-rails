# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'the import map' do
  let(:import_map) { JSON.parse(page.find('script[type=importmap]', visible: :all).text(:all)) }
  let(:imports) { import_map.fetch('imports') }
  let(:preloads) { page.all('link[rel=modulepreload]', visible: :all).map { |link| link[:href] } }

  before { get root_path }

  it 'points each import at its digested, vendored file' do
    expect(imports.fetch('tom-select')).to match(
      %r{\A/assets/ga\.jspm\.io/npm/tom-select@2\.4\.3/dist/esm/tom-select\.complete-\h+\.js\z}
    )
  end

  it 'scopes the dependencies of vendored modules to their directory' do
    expect(import_map.fetch('scopes').keys).to contain_exactly('/assets/', '/assets/ga.jspm.io/')
  end

  it 'sends a relative import to the digested file' do
    expect(imports.fetch('/assets/greeting.js')).to match(%r{\A/assets/greeting-\h+\.js\z})
  end

  it 'preloads the modules the entry imports statically' do
    expect(preloads).to include(
      a_string_matching(%r{\A/assets/greeting-\h+\.js\z}),
      a_string_matching(%r{\A/assets/ga\.jspm\.io/npm/tom-select@2\.4\.3/})
    )
  end

  it 'leaves the dynamically imported modules for later' do
    expect(preloads).not_to include(a_string_including('katex'))
  end

  it 'serves every module it names' do
    scoped = import_map.fetch('scopes').values.flat_map(&:values)
    entry = page.find('script[type=module]', visible: :all)[:src]
    urls = [*imports.values, *scoped, *preloads, entry]
    statuses =
      urls.uniq.to_h do |url|
        get(url)
        [url, response.status]
      end

    expect(statuses.reject { |_url, status| status == 200 }).to eq({})
  end
end
