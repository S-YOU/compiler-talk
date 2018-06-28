require 'set'

module Crystal
  class Parser < Lexer
    def self.parse(str)
      new(str).parse
    end

    def initialize(str)
      super
      @def_vars = [Set.new]
      next_token_skip_statement_end
    end

    def parse
      exps = parse_expressions
    end

    def parse_expressions
      exps = []
      while @token.type != :EOF && !is_end_token
        exps << parse_expression
        skip_statement_end
      end
      # exps.each do |x|
      #   p [x.to_s, x.respond_to?(:name) ? x.name : nil]
      # end
      Expressions.new exps
    end

    def parse_expression
      atomic = parse_assign
    end

    def parse_assign
      atomic = parse_or

      while true

        case @token.type
        when :SPACE
          next_token
        when :'='
          break unless can_be_assigned?(atomic)

          atomic = Var.new atomic.name
          push_var atomic

          next_token_skip_space_or_newline

          value = parse_assign
          atomic = Assign.new(atomic, value)
        when :'+='
          break unless can_be_assigned?(atomic)

          atomic = Var.new atomic.name
          push_var atomic

          method = @token.type.to_s[0 .. -2].to_sym

          next_token_skip_space_or_newline

          value = parse_assign
          atomic = Assign.new(atomic, Call.new(atomic, method, [value]))
        else
          break
        end
      end

      atomic
    end

    def self.parse_operator(name, next_operator, *operators)
      class_eval %Q(
        def parse_#{name}
          left = parse_#{next_operator}
          while true
            case @token.type
            when :SPACE
              next_token
            when #{operators.map{|x| ':"' + x.to_s + '"'}.join ', '}
              method = @token.type
              next_token_skip_space_or_newline
              right = parse_#{next_operator}
              left = Call.new left, method, [right]
            else
              return left
            end
          end
        end
      )
    end

    parse_operator :or, :and, :'||'
    parse_operator :and, :equality, :'&&'
    parse_operator :equality, :cmp, :<, :<=, :>, :>=
    parse_operator :cmp, :add_or_sub, :==, :"!="

    def parse_add_or_sub
      left = parse_mul_or_div
      while true
        case @token.type
        when :SPACE
          next_token
        when :+, :-
          method = @token.type
          next_token_skip_space_or_newline
          right = parse_mul_or_div
          left = Call.new left, method, [right]
        when :INT
          case @token.value[0]
          when '+'
            left = Call.new left, @token.value[0].to_sym, [Int.new(@token.value)]
            next_token_skip_space_or_newline
          when '-'
            left = Call.new left, @token.value[0].to_sym, [Int.new(@token.value[1 .. -1])]
            next_token_skip_space_or_newline
          else
            return left
          end
        when :FLOAT
          case @token.value[0]
          when '+'
            left = Call.new left, @token.value[0].to_sym, [Float.new(@token.value)]
            next_token_skip_space_or_newline
          when '-'
            left = Call.new left, @token.value[0].to_sym, [Float.new(@token.value[1 .. -1])]
            next_token_skip_space_or_newline
          else
            return left
          end
        else
          return left
        end
      end
    end

    parse_operator :mul_or_div, :atomic, :*, :/

    def parse_atomic
      case @token.type
      when :'('
        next_token_skip_space_or_newline
        exp = parse_expression
        check :')'
        next_token_skip_statement_end
        raise_error "unexpected token: (" if @token.type == :'('
        exp
      when :INT
        node_and_next_token Int.new(@token.value)
      when :FLOAT
        node_and_next_token Float.new(@token.value)
      when :CHAR
        node_and_next_token Char.new(@token.value)
      when :KEYWORD
        case @token.value
        when :false
          node_and_next_token Bool.new(false)
        when :true
          node_and_next_token Bool.new(true)
        when :def
          parse_def
        when :if
          parse_if
        when :while
          parse_while
        else
          raise_error "unexpected keyword: #{@token.to_s}"
        end
      when :IDENT
        parse_var_or_call
      else
        raise_error "unexpected token: #{@token.to_s}"
      end
    end

    def parse_var_or_call
      name = @token.value
      next_token

      args = parse_args

      if args
        Call.new(nil, name, args)
      elsif is_var? name
        Var.new name
      else
        Call.new nil, name, []
      end
    end

    def parse_args
      case @token.type
      when :"("
        args = []
        next_token_skip_space
        while @token.type != :")"
          args << parse_expression
          skip_space
          if @token.type == :","
            next_token_skip_space_or_newline
          end
        end
        next_token_skip_space
        args
      when :SPACE
        next_token
        case @token.type
        when :CHAR, :INT, :FLOAT, :IDENT, :'('
          args = []
          while @token.type != :NEWLINE && @token.type != :";" && @token.type != :EOF && @token.type != :')' && !is_end_token
            args << parse_assign
            skip_space
            if @token.type == :","
              next_token_skip_space_or_newline
            else
              break
            end
          end
          args
        else
          nil
        end
      else
        nil
      end
    end

    def parse_def
      next_token_skip_space_or_newline
      check :IDENT, :"=", :<<, :<, :<=, :==, :"!=", :>>, :>, :>=, :+, :-, :*, :/

      name = @token.type == :IDENT ? @token.value : @token.type
      args = []

      next_token_skip_space

      case @token.type
      when :'('
        next_token_skip_space_or_newline
        while @token.type != :')'
          check_ident
          args << Var.new(@token.value)
          next_token_skip_space_or_newline
          if @token.type == :','
            next_token_skip_space_or_newline
          end
        end
        next_token_skip_statement_end
      when :IDENT
        while @token.type != :NEWLINE && @token.type != :";"
          check_ident
          args << Var.new(@token.value)
          next_token_skip_space
          if @token.type == :','
            next_token_skip_space_or_newline
          end
        end
        next_token_skip_statement_end
      else
        skip_statement_end
      end

      if @token.type == :KEYWORD && @token.value == :end
        body = nil
      else
        body = push_def(args) { parse_expressions }
        skip_statement_end
        check_ident :end
      end

      next_token_skip_statement_end

      Def.new name, args, body
    end

    def parse_if(check_end = true)
      next_token_skip_space_or_newline

      cond = parse_expression
      skip_statement_end

      a_then = parse_expressions
      skip_statement_end

      a_else = nil
      if @token.type == :KEYWORD
        case @token.value
        when :else
          next_token_skip_statement_end
          a_else = parse_expressions
        when :elsif
          a_else = parse_if false
        end
      end

      if check_end
        check_ident :end
        next_token_skip_space
      end

      node = If.new cond, a_then, a_else
      node
    end

    def parse_while
      next_token_skip_space_or_newline

      cond = parse_expression
      skip_statement_end

      body = parse_expressions
      skip_statement_end

      check_ident :end
      next_token_skip_statement_end

      node = While.new cond, body
      node
    end

    def node_and_next_token(node)
      next_token
      node
    end

    private

    def check(*token_types)
      raise_error "expecting token #{token_types}" unless token_types.any?{|type| @token.type == type}
    end

    def check_ident(value = nil)
      if value
        raise_error "expecting token: #{value}" unless @token.type == :KEYWORD && @token.value == value
      else
        raise_error "unexpected token: #{@token.to_s}" unless @token.type == :IDENT && @token.value.is_a?(String)
      end
    end

    def is_end_token
      return false unless @token.type == :KEYWORD

      case @token.value
      when :end, :else, :elsif
        true
      else
        false
      end
    end

    def push_def(args)
      @def_vars.push(Set.new args.map(&:name))
      ret = yield
      @def_vars.pop
      ret
    end

    def push_var(*vars)
      vars.each do |var|
        @def_vars.last.add var.name
      end
    end

    def is_var?(name)
      name == 'self' || @def_vars.last.include?(name)
    end

    def can_be_assigned?(node)
      node.is_a?(Var) || (node.is_a?(Call) && node.obj.nil? && node.args.length == 0)
    end
  end

  def parse(string)
    Parser.parse string
  end
end
