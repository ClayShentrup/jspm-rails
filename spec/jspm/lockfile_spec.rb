# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Jspm::Lockfile do
  context 'when node_modules lags behind yarn.lock' do
    let!(:yarn_app) { FixtureApp.copy('yarn') }

    before do
      installed = yarn_app.join('node_modules')
      source = installed.realpath
      installed.delete
      installed.mkpath
      source.children.each { |child| installed.join(child.basename).make_symlink(child) }
      stale = installed.join('tom-select')
      stale.delete
      stale.mkpath
      stale.join('package.json').write(JSON.generate(version: '2.3.0'))
    end

    after { FileUtils.rm_rf(yarn_app) }

    it 'pins a package Yarn locked once to that version' do
      expect(described_class.read(yarn_app).resolutions).to include('tom-select' => '2.4.3')
    end
  end
end
