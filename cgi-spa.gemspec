# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{cgi-spa}
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Sam Ruby}]
  s.date = %q{2011-12-24}
  s.description = %q{    Provides a number of globals, helper methods, and monkey patches which
    simplify the development of single page applications in the form of
    CGI scripts.
}
  s.email = %q{rubys@intertwingly.net}
  s.extra_rdoc_files = [%q{COPYING}, %q{README}, %q{lib/cgi-spa.rb}, %q{lib/cgi-spa/builder.rb}, %q{lib/cgi-spa/cgi-methods.rb}, %q{lib/cgi-spa/environment.rb}, %q{lib/cgi-spa/html-methods.rb}, %q{lib/cgi-spa/installation.rb}, %q{lib/cgi-spa/job-control.rb}, %q{lib/cgi-spa/version.rb}]
  s.files = [%q{COPYING}, %q{Manifest}, %q{README}, %q{Rakefile}, %q{cgi-spa.gemspec}, %q{lib/cgi-spa.rb}, %q{lib/cgi-spa/builder.rb}, %q{lib/cgi-spa/cgi-methods.rb}, %q{lib/cgi-spa/environment.rb}, %q{lib/cgi-spa/html-methods.rb}, %q{lib/cgi-spa/installation.rb}, %q{lib/cgi-spa/job-control.rb}, %q{lib/cgi-spa/version.rb}]
  s.homepage = %q{http://github.com/rubys/cgi-spa}
  s.rdoc_options = [%q{--line-numbers}, %q{--inline-source}, %q{--title}, %q{Cgi-spa}, %q{--main}, %q{README}]
  s.require_paths = [%q{lib}]
  s.rubyforge_project = %q{cgi-spa}
  s.rubygems_version = %q{1.8.5}
  s.summary = %q{CGI Single Page Applications}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
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
