# encoding: utf-8
$:.push File.expand_path("../lib", __FILE__)

require 'zg/version'

Gem::Specification.new do |s|
  s.name         = 'zg'
  s.version      = Zg::VERSION
  s.platform     = Gem::Platform::RUBY
  s.authors      = ["Nelson Gauthier"]
  s.email        = ["nelson@airbnb.com"]
  s.homepage     = "https://git.airbnb.com/airbnb/zg"
  s.summary      = "A sufficiently smart bulk loader"
  s.description  = s.summary

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- spec/*`.split("\n")
  s.require_path = 'lib'
end
