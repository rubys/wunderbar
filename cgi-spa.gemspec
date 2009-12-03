# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{cgi-spa}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sam Ruby"]
  s.date = %q{2009-12-03}
  s.description = %q{    Provides a number of globals, helper methods, and monkey patches which
    simplify the development of single page applications in the form of
    CGI scripts.
}
  s.email = %q{rubys@intertwingly.net}
  s.extra_rdoc_files = ["README", "lib/cgi-spa.rb", "lib/version.rb"]
  s.files = ["Manifest", "README", "Rakefile", "lib/cgi-spa.rb", "lib/version.rb", "cgi-spa.gemspec"]
  s.homepage = %q{http://github.com/rubys/cgi-spa}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Cgi-spa", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{cgi-spa}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{CGI Single Page Applications}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<builder>, [">= 0"])
      s.add_runtime_dependency(%q<json>, [">= 0"])
    else
      s.add_dependency(%q<builder>, [">= 0"])
      s.add_dependency(%q<json>, [">= 0"])
    end
  else
    s.add_dependency(%q<builder>, [">= 0"])
    s.add_dependency(%q<json>, [">= 0"])
  end
end
