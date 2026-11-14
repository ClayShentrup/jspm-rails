# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Jspm::Check do
  let!(:conflicted) { FixtureApp.copy('conflicted') }
  let(:asset_paths) { [conflicted.join('app/javascript')] }
  let(:import_map_file) { conflicted.join('config/importmap.json') }
  let(:output) { StringIO.new }

  after { FileUtils.rm_rf(conflicted) }

  it 'passes `rails jspm:check` right after an install' do
    check_output, status = Open3.capture2e('bin/rails', 'jspm:check', chdir: DummyInstall::DIRECTORY)

    aggregate_failures do
      expect(check_output).to eq("          ok  nothing to install\n")
      expect(status).to be_success
    end
  end

  context 'when package-lock.json moved on since the install' do
    before do
      Jspm::Install.call(
        asset_directories: %w[tom-select],
        asset_paths:,
        output: StringIO.new,
        root: conflicted
      )
      import_map_file.write(import_map_file.read.gsub('tom-select@2.7.0', 'tom-select@2.4.1'))
    end

    it 'fails, and says to install' do
      passed = described_class.call(
        asset_directories: %w[tom-select],
        asset_paths:,
        output:,
        root: conflicted
      )

      aggregate_failures do
        expect(output.string.lines).to eq(
          [
            "       stale  config/importmap.json\n",
            "         run  bin/rails jspm:install\n"
          ]
        )
        expect(passed).to be(false)
      end
    end
  end

  context "when a package's stylesheet changed since the install" do
    before do
      Jspm::Install.call(
        asset_directories: %w[tom-select],
        asset_paths:,
        output: StringIO.new,
        root: conflicted
      )
      conflicted.join('vendor/jspm/tom-select/dist/css/tom-select.css').write('')
    end

    it 'fails, and names the stylesheet' do
      passed = described_class.call(
        asset_directories: %w[tom-select],
        asset_paths:,
        output:,
        root: conflicted
      )

      aggregate_failures do
        expect(output.string.lines).to eq(
          [
            "       stale  vendor/jspm/tom-select/dist/css/tom-select.css\n",
            "         run  bin/rails jspm:install\n"
          ]
        )
        expect(passed).to be(false)
      end
    end
  end

  context 'when a vendored module is gone' do
    before do
      Jspm::Install.call(
        asset_directories: %w[tom-select],
        asset_paths:,
        output: StringIO.new,
        root: conflicted
      )
      conflicted.join('vendor/jspm/ga.jspm.io/npm/tom-select@2.7.0/dist/esm/constants.js').delete
    end

    it 'fails, and names the module' do
      passed = described_class.call(
        asset_directories: %w[tom-select],
        asset_paths:,
        output:,
        root: conflicted
      )

      aggregate_failures do
        expect(output.string.lines).to eq(
          [
            "     missing  vendor/jspm/ga.jspm.io/npm/tom-select@2.7.0/dist/esm/constants.js\n",
            "         run  bin/rails jspm:install\n"
          ]
        )
        expect(passed).to be(false)
      end
    end
  end
end
