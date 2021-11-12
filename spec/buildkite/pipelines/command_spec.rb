# frozen_string_literal: true

require 'pathname'

RSpec.describe Buildkite::Pipelines::Command do
  shared_examples 'command helper' do |method_name, command|
    it 'runs the command' do
      instance = double
      subcommand = double
      args = double

      expect(described_class).to receive(:new).with(command, subcommand, args).and_return(instance)
      expect(instance).to receive(:run)

      described_class.public_send(method_name, subcommand, args)
    end
  end

  describe '.pipeline!' do
    it 'aborts on failure' do
      args = double
      expect(described_class).to receive(:pipeline).with(args).and_return(false)

      expect {
        described_class.pipeline!(args)
      }.to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 1)))
    end
  end

  describe '.artifact!' do
    it 'aborts on failure' do
      args = double
      expect(described_class).to receive(:artifact).with(args).and_return(false)

      expect {
        described_class.artifact!(args)
      }.to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 1)))
    end
  end

  describe '.annotate!' do
    it 'aborts on failure' do
      args = double
      expect(described_class).to receive(:annotate).with(args).and_return(false)

      expect {
        described_class.annotate!(args)
      }.to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 1)))
    end
  end

  describe '.pipeline' do
    include_examples 'command helper', :pipeline, :pipeline
  end

  describe '.artifact' do
    include_examples 'command helper', :artifact, :artifact
  end

  describe '.annotate' do
    include_examples 'command helper', :annotate, :annotate
  end

  describe '.meta_data' do
    include_examples 'command helper', :meta_data, :"meta-data"
  end

  describe '#run' do
    let(:command) { :pipeline }
    let(:subcommand) { :upload }
    let(:options) { { foo_key: :foo_value, bar_key: :bar_value } }
    let(:args) { [Pathname.new('/path/to/foo'), Pathname.new('/path/to/bar')] }
    let(:instance) { described_class.new(command, subcommand, options, *args) }

    # Unstub to test system call
    before { Spec::Support::Command.unstub! }

    after { Spec::Support::Command.stub! }

    it 'runs the command' do
      expect(instance).to receive(:system).with(
        Buildkite::Pipelines::Command::BIN_PATH,
        command.to_s,
        subcommand.to_s,
        '--foo-key',
        'foo_value',
        '--bar-key',
        'bar_value',
        '/path/to/foo',
        '/path/to/bar'
      )

      instance.run
    end
  end
end
