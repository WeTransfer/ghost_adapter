require 'test_helper'
require 'ghost_adapter/version_checker'
require 'open3'

module GhostAdapter
  class VersionCheckerTest < MiniTest::Test
    def test_gh_ost_not_installed
      failed_process = OpenStruct.new('success?' => false)
      Open3.stub :capture2, ['', failed_process] do
        assert_raises(GhostAdapter::IncompatibleVersion) do
          VersionChecker.validate_executable!
        end
      end
    end

    def test_version_too_low
      success_process = OpenStruct.new('success?' => true)
      Open3.stub :capture2, ['0.1', success_process] do
        assert_raises(GhostAdapter::IncompatibleVersion) do
          VersionChecker.validate_executable!
        end
      end
    end

    def test_version_too_high
      success_process = OpenStruct.new('success?' => true)
      Open3.stub :capture2, ['10.0', success_process] do
        assert_raises(GhostAdapter::IncompatibleVersion) do
          VersionChecker.validate_executable!
        end
      end
    end

    def test_version_just_right
      success_process = OpenStruct.new('success?' => true)
      Open3.stub :capture2, ['1.2', success_process] do
        VersionChecker.validate_executable!
      end
    end
  end
end
