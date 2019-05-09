$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'jbuilder/pagination'
require 'ostruct'
require 'pry'
require 'rspec/support/object_formatter'

RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length=2000