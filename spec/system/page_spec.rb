# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'a page using jspm-rails' do
  shared_examples 'a working page' do
    before { page.goto(root_path) }

    it 'runs modules the entry imports by relative path' do
      expect(page.get_by_text('Hello from a relative import')).to be_visible
    end

    it 'runs a directory\'s index module, imported by the directory\'s name' do
      expect(page.get_by_text('Themed by an index module')).to be_visible
    end

    it 'runs an app module imported by a name computed at runtime' do
      expect(page.get_by_text('Loaded by a computed name')).to be_visible
    end

    it "runs a module from an engine's assets" do
      expect(page.get_by_text('Hello from an engine')).to be_visible
    end

    it 'runs a dependency spread across many vendored files' do
      expect(page.get_by_role('combobox', name: 'Flavor')).to be_visible
    end

    it 'renders math with a dynamically imported module' do
      formula = page.get_by_role('region', name: 'Formula')

      expect(formula.get_by_role('math')).to be_attached
    end
  end

  it_behaves_like 'a working page'

  it 'loads another entry module on a layout that names it' do
    page.goto('/admin')

    expect(page.get_by_text('Hello from a relative import, in admin')).to be_visible
  end

  context 'with assets on another origin' do
    around do |example|
      asset_host = "http://localhost:#{Capybara.current_session.server.port}"
      ActionController::Base.with(asset_host:) { example.run }
    end

    it_behaves_like 'a working page'
  end
end
