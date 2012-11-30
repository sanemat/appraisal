module AppraisalHelpers
  def add_from_this_project_as_dependency(gem_name)
    append_to_file('Gemfile', %{\ngem "#{gem_name}", :path => "#{PROJECT_ROOT}"})
  end

  def install_dummy_gems(gems_hash)
    gems_hash.each do |name, version|
      name = name.to_s
      create_dir(name)
      cd(name)
      create_dir("lib")
      gem_path = "#{name}.gemspec"
      version_path = "lib/#{name}.rb"
      spec = <<-SPEC
      Gem::Specification.new do |s|
        s.name    = '#{name}'
        s.version = '#{version}'
        s.authors = 'Mr. Smith'
        s.summary = 'summary'
        s.files   = '#{version_path}'
      end
      SPEC
      write_file(gem_path, spec)
      write_file(version_path, "$#{name}_version = '#{version}'")
      in_current_dir { `gem build #{gem_path} 2>&1` }
      set_env("GEM_HOME", TMP_GEM_ROOT)
      in_current_dir { `gem install #{name}-#{version}.gem 2>&1` }
      FileUtils.rm_rf(File.join(current_dir, name))
      dirs.pop
    end
  end
end

RSpec.configure do |c|
  c.include AppraisalHelpers
end


