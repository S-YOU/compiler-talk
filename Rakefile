task :console do
  require 'irb'
  require 'bundler/setup'
  require 'pry'
  require 'pry-nav'
  require 'llvm/core'
  require_relative 'lib/crystal'
  include Crystal
  ARGV.clear
  IRB.start
end