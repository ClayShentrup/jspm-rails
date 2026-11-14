# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Jspm::LocalModules do
  subject(:local_modules) { described_class.find(asset_paths: []) }

  it 'names a scope at the filesystem root as the asset root' do
    expect(local_modules.localize('/')).to eq('asset:')
  end
end
