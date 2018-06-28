module Crystal
  class Exception < StandardError
  end

  class ASTNode
  end

  class Visitor
  end
end

require_relative "crystal/ast"

Dir["#{File.expand_path('../',  __FILE__)}/**/*.rb"].each do |filename|
  require filename
end
