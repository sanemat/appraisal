require 'rubygems'
require 'bundler/setup'
require 'aruba/api'

Dir["spec/support/**/*.rb"].each { |f| require File.expand_path(f) }

RSpec.configure do |config|
  include Aruba::Api

  config.before(:suite, :type => :integration) do
    PROJECT_ROOT = File.expand_path('../..', __FILE__).freeze
    TMP_GEM_ROOT = File.join(PROJECT_ROOT, "tmp", "gems")
  end

  config.before(:each, :type => :integration) do
    # Extend the timeout before Aruba will kill the process to 5 minutes.
    @aruba_timeout_seconds = 5 * 60 * 60

    FileUtils.rm_rf(TMP_GEM_ROOT)
    FileUtils.mkdir_p(TMP_GEM_ROOT)

    ENV["GEM_PATH"] = [TMP_GEM_ROOT, ENV["GEM_PATH"]].join(":")
  end
end

