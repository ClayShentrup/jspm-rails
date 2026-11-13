# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'a page using jspm-rails' do
  def katex_font_loaded?
    page.evaluate(<<~JS)
      () => document.fonts.ready.then((fonts) =>
        [...fonts].some((face) => face.family === 'KaTeX_Main' && face.status === 'loaded')
      )
    JS
  end

  shared_examples 'a working page' do
    before { page.goto(root_path) }

    it 'runs modules the entry imports by relative path' do
      expect(page.get_by_text('Hello from a relative import')).to be_visible
    end

    it 'runs a dependency spread across many vendored files' do
      expect(page.get_by_role('combobox', name: 'Flavor')).to be_visible
    end

    it 'renders math with a dynamically imported module and its npm stylesheet and fonts' do
      formula = page.get_by_role('region', name: 'Formula')
      expect(formula.get_by_role('math')).to be_attached

      expect(katex_font_loaded?).to be(true)
    end
  end

  it_behaves_like 'a working page'

  context 'with assets on another origin' do
    around do |example|
      asset_host = proc { |_source, request| "#{request.protocol}localhost:#{request.port}" }
      ActionController::Base.with(asset_host:, &example)
    end

    it_behaves_like 'a working page'
  end
end
