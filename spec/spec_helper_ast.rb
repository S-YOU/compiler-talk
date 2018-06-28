module Crystal
  class Expressions < ASTNode
    def ==(other)
      other.class == self.class && other.expressions == expressions
    end
  end

  class Bool < ASTNode
    def ==(other)
      other.class == self.class && other.value == value
    end
  end

  class Int < ASTNode
    def ==(other)
      other.class == self.class && other.value.to_i == value.to_i
    end
  end

  class Float < ASTNode
    def ==(other)
      other.class == self.class && other.value.to_f == value.to_f
    end
  end

  class Char < ASTNode
    def ==(other)
      other.class == self.class && other.value.to_i == value.to_i
    end
  end

  class Def < ASTNode
    def ==(other)
      other.class == self.class && other.name == name && other.args == args && other.body == body
    end
  end

  class Var < ASTNode
    def ==(other)
      other.class == self.class && other.name == name
    end
  end

  class Call < ASTNode
    def ==(other)
      other.class == self.class && other.obj == obj && other.name == name && other.args == args
    end
  end

  class If < ASTNode
    def ==(other)
      other.class == self.class && other.cond == cond && other.then == self.then && other.else == self.else
    end
  end

  class Assign < ASTNode
    def ==(other)
      other.class == self.class && other.target == target && other.value == value
    end
  end

  class While < ASTNode
    def ==(other)
      other.class == self.class && other.cond == cond && other.body == body
    end
  end
end
