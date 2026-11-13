# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'a page using jspm-rails' do
  def katex_font_status
    page.evaluate_async_script(<<~JS)
      const done = arguments[0]
      document.fonts.ready.then(() => {
        const font = [...document.fonts].find((face) => face.family === 'KaTeX_Main' && face.status === 'loaded')
        done(font ? 'loaded' : 'missing')
      })
    JS
  end

  shared_examples 'a working page' do
    before { visit root_path }

    it 'runs modules the entry imports by relative path' do
      expect(page).to have_text('Hello from a relative import')
    end

    it 'runs a dependency spread across many vendored files' do
      expect(page).to have_css('[role=combobox]')
    end

    it 'renders math with a dynamically imported module and its npm stylesheet and fonts' do
      expect(page).to have_selector(:element, 'p', 'aria-label': 'Formula') { |formula|
        formula.has_selector?(:element, 'math')
      }

      expect(katex_font_status).to eq('loaded')
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
