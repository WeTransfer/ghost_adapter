require 'open3'

module GhostAdapter
  class IncompatibleVersion < StandardError
    def initialize(version = nil)
      message = %(
#{version.nil? ? 'gh-ost not installed' : "gh-ost incompatible version #{version} installed."}
please install version: [#{VersionChecker::ALLOWED_RANGE}]
for latest release, visit: https://github.com/github/gh-ost/releases/latest)
      super(message)
    end
  end

  class VersionChecker
    ALLOWED_RANGE = Gem::Requirement.new('>= 1.1.0', '< 2')

    class << self
      def validate_executable!
        found_version = fetch_version
        raise IncompatibleVersion, found_version unless ALLOWED_RANGE.satisfied_by? found_version
      end

      private

      def fetch_version
        stdout, status = Open3.capture2('gh-ost', '--version')
        raise IncompatibleVersion unless status.success?

        begin
          Gem::Version.new(stdout)
        rescue ArgumentError
          raise IncompatibleVersion
        end
      end
    end
  end
end
