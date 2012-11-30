require "spec_helper"

describe "run a rake task through several appraisals", :type => :integration do
  before do
    @puts = true
    unset_bundler_env_vars
  end

  before do
    create_dir("projecto")
    install_dummy_gems({
      :dummy_girl => '1.3.0',
      :dummy_girl => '1.3.2',
      :dummy_rake => '0.8.7',
      :dummy_rake => '0.9.0',
      :dummy_sass => '3.1.0',
      :dummy_spec => '3.1.9'
    })
    cd("projecto")
    write_file("Gemfile", <<-EOGEMFILE)
    gem "dummy_rake", "0.8.7"
    gem "dummy_girl"
    group :assets do
      gem 'dummy_sass', "  ~> 3.1.0"
    end
    group :test, :development do
      gem 'dummy_spec', "  ~> 3.1.0"
    end
    EOGEMFILE

    add_from_this_project_as_dependency("appraisal")
    write_file("Appraisals", <<-EOAPPRAISALS)
    appraise "1.3.2" do
      gem "dummy_girl", "1.3.2"
    end
    appraise "1.3.0" do
      gem "dummy_girl", "1.3.0"
      gem "dummy_rake", "0.9.0"
    end
    EOAPPRAISALS

    write_file("Rakefile", <<-EORAKEFILE)
    require 'rubygems'
    require 'bundler/setup'
    require 'appraisal'
    task :version do
      require 'dummy_girl'
      puts "Loaded #{$dummy_girl_version}"
    end
    task :fail do
      require 'dummy_girl'
      puts "Fail #{$dummy_girl_version}"
      raise
    end
    task :default => :version
    EORAKEFILE

    run_successfully("bundle install --local")
    run_successfully("bundle exec rake appraisal:install --trace")
  end

  it "runs a specific task with one appraisal" do
    run_successfully("bundle exec rake appraisal:1.3.0 version --trace")
    assert_output_contains("Loaded 1.3.0")
  end

  it "runs a specific task with all appraisals" do
    run_successfully("bundle exec rake appraisal version --trace")
    assert_output_contains("Loaded 1.3.0")
    assert_output_contains("Loaded 1.3.2")
    assert_output_does_not_contain("Invoke version")
  end

  it "runs the default task with one appraisal" do
    run_successfully("bundle exec rake appraisal:1.3.0 --trace")
    assert_output_contains("Loaded 1.3.0")
  end

  it "runs the default task with all appraisals" do
    run_successfully("bundle exec rake appraisal --trace")
    assert_output_contains("Loaded 1.3.0")
    assert_output_contains("Loaded 1.3.2")
  end

  it "runs a failing task with one appraisal" do
    run_unsuccessfully("bundle exec rake appraisal:1.3.0 fail --trace")
    assert_output_contains("Fail 1.3.0")
    assert_exit_status(1)
  end

  it "runs a failing task with all appraisals" do
    run_unsuccessfully("bundle exec rake appraisal fail --trace")
    assert_output_contains("Fail 1.3.2")
    assert_output_does_not_contain("Fail 1.3.0")
    assert_exit_status(1)
  end

  it "runs a cleanup task" do
    run_unsuccessfully("bundle exec rake appraisal:cleanup --trace")
    assert_file_does_not_exist("gemfiles/1.3.0.gemfile")
    assert_file_does_not_exist("gemfiles/1.3.0.gemfile.lock")
    assert_file_does_not_exist("gemfiles/1.3.2.gemfile")
    assert_file_does_not_exist("gemfiles/1.3.2.gemfile.lock")
  end

  def run_successfully(command)
    run_simple(command)
  end

  def run_unsuccessfully(command)
    run_simple(command, false)
  end

  def assert_file_does_not_exist(file_name)
    check_file_presence([file_name], false)
  end

  def assert_output_contains(expected)
    assert_partial_output(expected, all_output)
  end

  def assert_output_does_not_contain(unexpected)
    assert_no_partial_output(unexpected, all_output)
  end
end
