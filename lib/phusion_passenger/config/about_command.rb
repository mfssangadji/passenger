#  Phusion Passenger - https://www.phusionpassenger.com/
#  Copyright (c) 2010-2013 Phusion
#
#  "Phusion Passenger" is a trademark of Hongli Lai & Ninh Bui.
#
#  See LICENSE file for license information.

PhusionPassenger.require_passenger_lib 'constants'
PhusionPassenger.require_passenger_lib 'config/command'

module PhusionPassenger
module Config

class AboutCommand < Command
	def self.description
		return "Show information about #{PROGRAM_NAME}"
	end

	def self.help
		puts "Usage: passenger-config about <SUBCOMMAND>"
		puts "Show information about #{PROGRAM_NAME}."
		puts
		puts "Available subcommands:"
		puts "  root                     Show #{PROGRAM_NAME}'s root directory."
		puts "  ruby-libdir              Show #{PROGRAM_NAME}'s Ruby library directory."
		puts "  includedir               Show the Nginx runtime library headers directory."
		puts "  nginx-addon-dir          Show #{PROGRAM_NAME}'s Nginx addon directory."
		puts "  nginx-libs               Show Nginx runtime library flags."
		puts "  compiled                 Check whether runtime libraries are compiled."
		puts "  natively-packaged        Check whether Phusion Passenger is natively"
		puts "                           packaged."
		puts "  installed-from-release-package  Check whether this installation came from"
		puts "                                  an official release package."
		puts "  make-locations-ini       Generate a locations.ini based on the current"
		puts "                           install paths."
		puts "  detect-apache2           Autodetect Apache installations."
		puts "  ruby-command             Show the correct command for invoking the Ruby"
		puts "                           interpreter."
		puts "  rubyext-compat-id        Show the Ruby extension binary compatibility ID."
		puts "  cxx-compat-id            Show the C++ binary compatibility ID."
		puts "  version                  Show the version number."
	end

	def run
		PhusionPassenger.require_passenger_lib 'platform_info'
		PhusionPassenger.require_passenger_lib 'platform_info/compiler'

		subcommand = @argv[0].to_s.dup
		# Compatibility with version <= 4.0.29: accept both
		# 'subcommand' and '--subcommand'.
		subcommand = "--#{subcommand}" if subcommand !~ /^--/

		case subcommand
		when "--root"
			puts PhusionPassenger.source_root
		when "--ruby-libdir"
			puts PhusionPassenger.ruby_libdir
		when "--includedir"
			puts PhusionPassenger.include_dir
		when "--nginx-addon-dir"
			puts PhusionPassenger.nginx_module_source_dir
		when "--nginx-libs"
			puts "#{common_library.link_objects_as_string} #{PhusionPassenger.lib_dir}/common/libboost_oxt.a"
		when "--compiled"
			common_library.link_objects.each do |filename|
				if !File.exist?(filename)
					exit 1
				end
			end
			if File.exist?("#{PhusionPassenger.lib_dir}/common/libboost_oxt.a")
				exit 0
			else
				exit 1
			end
		when "--natively-packaged"
			if PhusionPassenger.natively_packaged?
				exit 0
			else
				exit 1
			end
		when "--installed-from-release-package"
			if PhusionPassenger.installed_from_release_package?
				exit 0
			else
				exit 1
			end
		when "--make-locations-ini"
			puts "[locations]"
			puts "natively_packaged=#{PhusionPassenger.natively_packaged?}"
			if PhusionPassenger.natively_packaged?
				puts "native_packaging_method=#{PhusionPassenger.native_packaging_method}"
			end
			PhusionPassenger::REQUIRED_LOCATIONS_INI_FIELDS.each do |field|
				puts "#{field}=#{PhusionPassenger.send(field)}"
			end
			PhusionPassenger::OPTIONAL_LOCATIONS_INI_FIELDS.each do |field|
				if value = PhusionPassenger.send(field)
					puts "#{field}=#{value}"
				end
			end
		when "--detect-apache2"
			PhusionPassenger.require_passenger_lib 'platform_info/apache_detector'
			detector = PhusionPassenger::PlatformInfo::ApacheDetector.new(STDOUT)
			begin
				detector.detect_all
				detector.report
			ensure
				detector.finish
			end
		when "--ruby-command"
			PhusionPassenger.require_passenger_lib 'platform_info/ruby'
			ruby = PhusionPassenger::PlatformInfo.ruby_command
			puts "passenger-config was invoked through the following Ruby interpreter:"
			puts "  Command: #{ruby}"
			STDOUT.write "  Version: "
			STDOUT.flush
			system("/bin/sh -c '#{ruby} -v'")
			puts "  To use in Apache: PassengerRuby #{ruby}"
			puts "  To use in Nginx : passenger_ruby #{ruby}"
			puts "  To use with Standalone: #{ruby} #{PhusionPassenger.bin_dir}/passenger start"
			puts

			ruby = PhusionPassenger::PlatformInfo.find_command('ruby')
			if ruby && !ruby.include?("rvm/rubies/")
				# If this is an RVM Ruby executable then we don't show it. We want people to
				# use the RVM wrapper scripts only.
				puts "The following Ruby interpreter was found first in $PATH:"
				puts "  Command: #{ruby}"
				STDOUT.write "  Version: "
				STDOUT.flush
				system("/bin/sh -c '#{ruby} -v'")
				puts "  To use in Apache: PassengerRuby #{ruby}"
				puts "  To use in Nginx : passenger_ruby #{ruby}"
				puts "  To use with Standalone: #{ruby} #{PhusionPassenger.bin_dir}/passenger start"
			elsif !ruby.include?("rvm/rubies/")
				puts "No Ruby interpreter found in $PATH."
			end
			puts
			puts "## Notes for RVM users"
			puts "Do you want to know which command to use for a different Ruby interpreter? 'rvm use' that Ruby interpreter, then re-run 'passenger-config --ruby-command'."
		when "--rubyext-compat-id"
			PhusionPassenger.require_passenger_lib 'platform_info/binary_compatibility'
			puts PhusionPassenger::PlatformInfo.ruby_extension_binary_compatibility_id
		when "--cxx-compat-id"
			PhusionPassenger.require_passenger_lib 'platform_info/binary_compatibility'
			puts PhusionPassenger::PlatformInfo.cxx_binary_compatibility_id
		when "--version"
			puts PhusionPassenger::VERSION_STRING
		when "--help"
			self.class.help
		else
			self.class.help
			exit 1
		end
	end

private
	def common_library
		PhusionPassenger.require_passenger_lib 'common_library'
		return COMMON_LIBRARY.
			only(*NGINX_LIBS_SELECTOR).
			set_output_dir("#{PhusionPassenger.lib_dir}/common/libpassenger_common")
	end
end

end # module Config
end # module PhusionPassenger
