
module Crystal
  # Base class for nodes in the grammar.
  class ASTNode
    attr_accessor :parent

    def self.inherited(klass)
      # Crystal::ClassName -> class_name
      name = klass.name.split('::')[-1].gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase

      klass.class_eval %Q(
        def accept(visitor)
          if visitor.visit_#{name} self
            accept_children visitor
          end
          visitor.end_visit_#{name} self
        end
      )

      Visitor.class_eval %Q(
        def visit_#{name}(node)
          true
        end

        def end_visit_#{name}(node)
        end
      )
    end

    def accept_children(visitor)
    end
  end

  # A container for one or many expressions.
  # A method's body and a block's body, for
  # example, are Expressions.
  class Expressions < ASTNode
    attr_accessor :expressions

    def self.from(obj)
      case obj
      when nil
        new []
      when Expressions
        obj
      when ::Array
        new obj
      else
        new [obj]
      end
    end

    def initialize(expressions = [])
      @expressions = expressions
      @expressions.each { |e| e.parent = self }
    end

    def <<(exp)
      exp.parent = self
      @expressions << exp
    end

    def accept_children(visitor)
      @expressions.each { |exp| exp.accept visitor }
    end

    # include Enumerable

    def each(&block)
      @expressions.each(&block)
    end

    def [](i)
      @expressions[i]
    end

    def last
      @expressions.last
    end

    def first
      @expressions.first
    end

    def empty?
      @expressions.empty?
    end

    def any?(&block)
      @expressions.any?(&block)
    end
  end

  # A bool literal.
  #
  #     'true' | 'false'
  #
  class Bool < ASTNode
    attr_accessor :value

    def initialize(value)
      @value = value
    end
  end

  # An integer literal.
  #
  #     \d+
  #
  class Int < ASTNode
    attr_accessor :value

    def initialize(value)
      @value = value.to_i
    end
  end

  # A float literal.
  #
  #     \d+.\d+
  #
  class Float < ASTNode
    attr_accessor :value

    def initialize(value)
      @value = value.to_f
    end
  end

  # A char literal.
  #
  #     "'"."'"
  #
  class Char < ASTNode
    attr_accessor :value

    def initialize(value)
      @value = value
    end
  end

  # A method definition.
  #
  #     [ receiver '.' ] 'def' name
  #       body
  #     'end'
  #   |
  #     [ receiver '.' ] 'def' name '(' [ arg [ ',' arg ]* ] ')'
  #       body
  #     'end'
  #   |
  #     [ receiver '.' ] 'def' name arg [ ',' arg ]*
  #       body
  #     'end'
  #
  class Def < ASTNode
    attr_accessor :name
    attr_accessor :args
    attr_accessor :body

    def initialize(name, args, body = nil)
      @name = name
      @args = args
      @args.each { |arg| arg.parent = self } if @args
      @body = Expressions.from body
      @body.parent = self
    end

    def accept_children(visitor)
      args.each { |arg| arg.accept visitor }
      body.accept visitor
    end

    def clone
      self.class.new name, args.map(&:clone), body.clone
    end
  end

  # A local variable, instance variable, constant,
  # or def or block argument.
  class Var < ASTNode
    attr_accessor :name

    def initialize(name)
      @name = name
    end
  end

  # A method call.
  #
  #     [ obj '.' ] name '(' ')'
  #   |
  #     [ obj '.' ] name '(' arg [ ',' arg ]* ')'
  #   |
  #     [ obj '.' ] name arg [ ',' arg ]*
  #   |
  #     arg name arg
  #
  # The last syntax is for infix operators, and name will be
  # the symbol of that operator instead of a string.
  #
  class Call < ASTNode
    attr_accessor :obj
    attr_accessor :name
    attr_accessor :args

    def initialize(obj, name, args = [])
      @obj = obj
      @obj.parent = self if @obj
      @name = name
      @args = args || []
      @args.each { |arg| arg.parent = self }
    end

    def accept_children(visitor)
      obj.accept visitor if obj
      args.each { |arg| arg.accept visitor }
    end
  end

  # An if expression.
  #
  #     'if' cond
  #       then
  #     [
  #     'else'
  #       else
  #     ]
  #     'end'
  #
  # An if elsif end is parsed as an If whose
  # else is another If.
  class If < ASTNode
    attr_accessor :cond
    attr_accessor :then
    attr_accessor :else

    def initialize(cond, a_then, a_else = nil)
      @cond = cond
      @cond.parent = self
      @then = Expressions.from a_then
      @then.parent = self
      @else = Expressions.from a_else
      @else.parent = self
    end

    def accept_children(visitor)
      self.cond.accept visitor
      self.then.accept visitor
      self.else.accept visitor if self.else
    end
  end

  # Assign expression.
  #
  #     target '=' value
  #
  class Assign < ASTNode
    attr_accessor :target
    attr_accessor :value

    def initialize(target, value)
      @target = target
      @target.parent = self
      @value = value
      @value.parent = self
    end

    def accept_children(visitor)
      target.accept visitor
      value.accept visitor
    end
  end

  # While expression.
  #
  #     'while' cond
  #       body
  #     'end'
  #
  class While < ASTNode
    attr_accessor :cond
    attr_accessor :body

    def initialize(cond, body = nil)
      @cond = cond
      @cond.parent = self
      @body = Expressions.from body
      @body.parent = self
    end

    def accept_children(visitor)
      cond.accept visitor
      body.accept visitor
    end
  end
end
