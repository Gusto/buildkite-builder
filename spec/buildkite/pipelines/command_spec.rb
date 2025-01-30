# frozen_string_literal: true

require 'pathname'
require 'open3'

RSpec.describe Buildkite::Pipelines::Command do
  shared_examples 'command helper' do |method_name, command|
    it 'runs the command' do
      instance = double
      subcommand = double
      args = double
      result = instance_double(described_class::Result, success?: true)

      expect(described_class).to receive(:new).with(command, subcommand, args).and_return(instance)
      expect(instance).to receive(:run).and_return(result)

      described_class.public_send(method_name, subcommand, args)
    end
  end

  describe '.pipeline!' do
    it 'aborts on failure' do
      args = double
      expect(described_class).to receive(:pipeline).with(args, exception: true).and_raise(described_class::CommandFailedError)

      expect {
        described_class.pipeline!(args)
      }.to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 1)))
    end
  end

  describe '.artifact!' do
    it 'aborts on failure' do
      args = double
      expect(described_class).to receive(:artifact).with(args, exception: true).and_raise(described_class::CommandFailedError)

      expect {
        described_class.artifact!(args)
      }.to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 1)))
    end
  end

  describe '.annotate!' do
    it 'aborts on failure' do
      args = double
      expect(described_class).to receive(:annotate).with(args, exception: true).and_raise(described_class::CommandFailedError)

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
    let(:instance) { described_class.new(command, subcommand, *args, options) }
    let(:mock_status) { instance_double(Process::Status, success?: true) }

    before do
      allow(Open3).to receive(:capture3).and_return(['stdout', 'stderr', mock_status])
    end

    it 'runs the command' do
      expect(Open3).to receive(:capture3).with(
        Buildkite::Pipelines::Command::BIN_PATH,
        command.to_s,
        subcommand.to_s,
        '/path/to/foo',
        '/path/to/bar',
        '--foo-key',
        'foo_value',
        '--bar-key',
        'bar_value',
      )

      instance.run
    end

    it 'returns result object' do
      expect(instance.run).to be_an_instance_of(described_class::Result)
    end

    it 'returns the status success of the command when capture kwarg is false' do
      result = instance.run
      expect(result.success?).to eq(mock_status.success?)
    end
  end
end
