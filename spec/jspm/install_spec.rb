# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Jspm::Install do
  let!(:conflicted) { FixtureApp.copy('conflicted') }
  let(:dummy) { Pathname(DummyInstall::DIRECTORY) }

  after { FileUtils.rm_rf(conflicted) }

  it 'reports what it vendored' do
    expect(DummyInstall.output.lines).to eq(
      [
        "      traced  ./app/javascript/application.js\n",
        "    vendored  31 modules from ga.jspm.io\n",
        "       wrote  config/importmap.json\n"
      ]
    )
  end

  it 'maps each import to the version in package-lock.json' do
    import_map = JSON.parse(dummy.join('config/importmap.json').read)

    expect(import_map.fetch('imports')).to eq(
      'tom-select' => 'https://ga.jspm.io/npm:tom-select@2.4.3/dist/esm/tom-select.complete.js'
    )
  end

  it 'locks the dependencies of dependencies too' do
    import_map = JSON.parse(dummy.join('config/importmap.json').read)

    expect(import_map.fetch('scopes').fetch('https://ga.jspm.io/')).to eq(
      '@orchidjs/sifter' => 'https://ga.jspm.io/npm:@orchidjs/sifter@1.1.0/dist/esm/sifter.js',
      '@orchidjs/unicode-variants' =>
        'https://ga.jspm.io/npm:@orchidjs/unicode-variants@1.2.2/dist/esm/index.js'
    )
  end

  it 'vendors modules the entry imports dynamically' do
    katex = dummy.join('vendor/jspm/ga.jspm.io/npm/katex@0.16.11/dist/katex.mjs')

    expect(katex).to be_file
  end

  it 'vendors source maps' do
    source_map = dummy.join('vendor/jspm/ga.jspm.io/npm/katex@0.16.11/dist/katex.mjs.map')

    expect(source_map).to be_file
  end

  it 'leaves out packages only Node uses' do
    vendored = dummy.join('vendor/jspm/ga.jspm.io/npm').children.map { |child| child.basename.to_s }

    expect(vendored).to contain_exactly('@orchidjs', 'katex@0.16.11', 'tom-select@2.4.3')
  end

  context 'when package-lock.json disagrees with itself' do
    let(:output) { StringIO.new }

    before { described_class.call(output:, root: conflicted) }

    it 'warns about each version it could not honor' do
      expect(output.string.lines.last).to eq(
        '        warn  @orchidjs/unicode-variants: package-lock.json has 1.1.1 and 1.2.2, ' \
        "and the import map uses 1.1.1 everywhere\n"
      )
    end
  end

  context 'when an earlier install locked versions' do
    let(:imports) { JSON.parse(conflicted.join('config/importmap.json').read).fetch('imports') }

    before do
      locked = {
        imports: {
          'canvas-confetti' => 'https://ga.jspm.io/npm:canvas-confetti@1.6.0/dist/confetti.module.mjs',
          'tom-select' => 'https://ga.jspm.io/npm:tom-select@2.4.1/dist/esm/tom-select.complete.js'
        }
      }
      conflicted.join('config/importmap.json').write(JSON.generate(locked))
      described_class.call(output: StringIO.new, root: conflicted)
    end

    it 'keeps the version of a package npm never installed' do
      expect(imports.fetch('canvas-confetti')).to eq(
        'https://ga.jspm.io/npm:canvas-confetti@1.6.0/dist/confetti.module.mjs'
      )
    end

    it 'moves an npm package to the version in package-lock.json' do
      expect(imports.fetch('tom-select')).to eq(
        'https://ga.jspm.io/npm:tom-select@2.7.0/dist/esm/tom-select.complete.js'
      )
    end
  end

  context 'when an earlier install left files behind' do
    before do
      stale = conflicted.join('vendor/jspm/stale.js')
      stale.dirname.mkpath
      stale.write('')
      described_class.call(output: StringIO.new, root: conflicted)
    end

    it 'removes them' do
      expect(conflicted.join('vendor/jspm/stale.js')).not_to exist
    end
  end

  context "when the app hasn't installed @jspm/generator" do
    let(:untraceable) { Pathname(File.expand_path('../fixtures/untraceable', __dir__)) }

    it 'says the trace failed' do
      install = -> { described_class.call(output: StringIO.new, root: untraceable) }

      expect(&install).to raise_error(Jspm::Error, 'tracing ./app/javascript/application.js failed')
    end
  end
end
