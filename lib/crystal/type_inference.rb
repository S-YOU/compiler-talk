module Crystal
  class ASTNode
    attr_accessor :type
  end

  class Call < ASTNode
    attr_accessor :target_def
  end

  class Def < ASTNode
    attr_accessor :owner
    attr_accessor :instances

    def add_instance(a_def)
      @instances ||= {}
      @instances[a_def.args.map(&:type)] = a_def
    end

    def lookup_instance(arg_types)
      @instances && @instances[arg_types]
    end
  end

  def type(node)
    mod = Crystal::Module.new
    node.accept TypeVisitor.new(mod, node)
    mod
  end

  class TypeVisitor < Visitor
    attr_accessor :mod

    def initialize(mod, root)
      @mod = mod
      @root = root
      @scopes = [{vars: {}}]
    end

    def visit_bool(node)
      node.type = mod.bool
    end

    def visit_int(node)
      node.type = mod.int
    end

    def visit_float(node)
      node.type = mod.float
    end

    def visit_char(node)
      node.type = mod.char
    end

    def visit_assign(node)
      node.value.accept self
      node.type = node.target.type = node.value.type

      define_var node.target

      false
    end

    def visit_var(node)
      node.type = lookup_var node.name
    end

    def end_visit_expressions(node)
      if node.expressions.empty?
        node.type = mod.void
      else
        node.type = node.expressions.last.type
      end
    end

    def visit_def(node)
      mod.defs[node.name] = node
      false
    end

    def visit_call(node)
      if node.obj
        node.obj.accept self
        scope = node.obj.type
      else
        scope = mod
      end

      if scope == :unknown
        node.type = :unknown
        return false
      end

      untyped_def = scope.defs[node.name]

      unless untyped_def
        error = node.obj ? "undefined method" : "undefined local variable or method"
        error << " '#{node.name}'"
        error << " for #{node.obj.type.name}" if node.obj
        compile_error error, node.name.length
      end

      if node.args.length != untyped_def.args.length
        compile_error "wrong number of arguments for '#{node.name}' (#{node.args.length} for #{untyped_def.args.length})", node.name.length
      end

      node.args.each do |arg|
        arg.accept self
      end

      types = node.args.map(&:type)
      if types.include?(:unknown)
        node.type = :unknown
        return false
      end

      typed_def = untyped_def.lookup_instance(types)
      if typed_def && typed_def.body.type == :unknown && @scopes.any? { |s| s[:obj] == untyped_def }
        node.target_def = typed_def
        node.type = typed_def.body.type
        return
      end

      if !typed_def || typed_def.body.type == :unknown
        if untyped_def.is_a?(FrozenDef)
          error = "can't call "
          error << "#{scope.name}#" unless scope.is_a?(Module)
          error << "#{node.name} with types [#{types.map(&:name).join ', '}]"
          compile_error error, node.name.length
        end

        typed_def ||= untyped_def.clone
        typed_def.owner = node.obj.type if node.obj
        typed_def.body.type = :unknown

        with_new_scope(untyped_def) do
          # if node.obj
          #   self_var = Var.new("self")
          #   self_var.type = node.obj.type
          #   define_var self_var
          # end

          typed_def.args.each_with_index do |arg, i|
            typed_def.args[i].type = node.args[i].type
            define_var typed_def.args[i]
          end

          untyped_def.add_instance typed_def

          typed_def.body.accept self
          while typed_def.body.type.is_a?(::Array)
            typed_def.body.type = Type.unmerge(typed_def.body.type, :unknown)
            typed_def.body.accept self
          end
        end
      end

      node.target_def = typed_def
      node.type = typed_def.body.type

      false
    end

    def end_visit_if(node)
      node.type = node.then.type
      node.type = Type.merge(node.type, node.else.type) if node.else.any?
    end

    def end_visit_while(node)
      node.type = mod.void
    end

    def define_var(var)
      @scopes.last[:vars][var.name] = var.type
    end

    def lookup_var(name)
      @scopes.last[:vars][name] or raise "Bug: var '#{name}' not found"
    end

    def with_new_scope(obj)
      @scopes.push({vars: {}, obj: obj})
      yield
      @scopes.pop
    end

    def compile_error(message, length)
      scope = @scopes.last
      str = "Error: #{message}"
      str << " in '#{scope[:obj].name}'" if scope[:obj]
      raise Crystal::Exception.new(str.strip)
    end
  end
end
