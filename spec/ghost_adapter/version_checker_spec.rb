require 'spec_helper'
require 'ghost_adapter/version_checker'
require 'open3'

RSpec.describe GhostAdapter::VersionChecker do
  let(:failed_process) { OpenStruct.new('success?' => false) }
  let(:success_process) { OpenStruct.new('success?' => true) }

  it 'raises an error if gh-ost is not installed' do
    expect(Open3).to receive(:capture2).and_return(['', failed_process])
    expect { described_class.validate_executable! }.to raise_error(GhostAdapter::IncompatibleVersion)
  end

  it 'raises an error if the version is below 1.1' do
    expect(Open3).to receive(:capture2).and_return(['0.1', success_process])
    expect { described_class.validate_executable! }.to raise_error(GhostAdapter::IncompatibleVersion)
  end

  it 'raises an error if the version is above 2.0' do
    expect(Open3).to receive(:capture2).and_return(['2.2', success_process])
    expect { described_class.validate_executable! }.to raise_error(GhostAdapter::IncompatibleVersion)
  end

  it 'succeeds if the version is between 1.1 and 2.0' do
    expect(Open3).to receive(:capture2).and_return(['1.2', success_process])
    expect { described_class.validate_executable! }.not_to raise_error
  end
end
