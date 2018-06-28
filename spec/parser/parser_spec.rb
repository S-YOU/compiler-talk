require 'spec_helper'

describe Parser do
  def self.it_parses(string, expected_nodes, options = {})
    it "parses #{string}", options do
      node = Parser.parse(string)
      node.should eq(Expressions.new expected_nodes)
    end
  end

  def self.it_parses_single_node(string, expected_node, options = {})
    it_parses string, [expected_node], options
  end

  it_parses_single_node "true", true.bool
  it_parses_single_node "false", false.bool

  it_parses_single_node "1", 1.int
  it_parses_single_node "+1", 1.int
  it_parses_single_node "-1", -1.int

  it_parses_single_node "1.0", 1.0.float
  it_parses_single_node "+1.0", 1.0.float
  it_parses_single_node "-1.0", -1.0.float

  it_parses_single_node "'a'", Char.new(?a.ord)

  it_parses_single_node "1 + 2", Call.new(1.int, :"+", [2.int])
  it_parses_single_node "1 +\n2", Call.new(1.int, :"+", [2.int])
  it_parses_single_node "1 +2", Call.new(1.int, :"+", [2.int])
  it_parses_single_node "1 -2", Call.new(1.int, :"-", [2.int])
  it_parses_single_node "1 +2.0", Call.new(1.int, :"+", [2.float])
  it_parses_single_node "1 -2.0", Call.new(1.int, :"-", [2.float])
  it_parses "1\n+2", [1.int, 2.int]
  it_parses "1;+2", [1.int, 2.int]
  it_parses_single_node "1 - 2", Call.new(1.int, :"-", [2.int])
  it_parses_single_node "1 -\n2", Call.new(1.int, :"-", [2.int])
  it_parses "1\n-2", [1.int, -2.int]
  it_parses "1;-2", [1.int, -2.int]
  it_parses_single_node "1 * 2", Call.new(1.int, :"*", [2.int])
  it_parses_single_node "1 * -2", Call.new(1.int, :"*", [-2.int])
  it_parses_single_node "2 * 3 + 4 * 5", Call.new(Call.new(2.int, :"*", [3.int]), :"+", [Call.new(4.int, :"*", [5.int])])
  it_parses_single_node "1 / 2", Call.new(1.int, :"/", [2.int])
  it_parses_single_node "1 / -2", Call.new(1.int, :"/", [-2.int])
  it_parses_single_node "2 / 3 + 4 / 5", Call.new(Call.new(2.int, :"/", [3.int]), :"+", [Call.new(4.int, :"/", [5.int])])
  it_parses_single_node "2 * (3 + 4)", Call.new(2.int, :"*", [Call.new(3.int, :"+", [4.int])])

  it_parses_single_node "1 && 2", Call.new(1.int, :'&&', [2.int])
  it_parses_single_node "1 || 2", Call.new(1.int, :'||', [2.int])

  it_parses_single_node "a = 1", Assign.new("a".var, 1.int)
  it_parses_single_node "a = b = 2", Assign.new("a".var, Assign.new("b".var, 2.int))

  it_parses_single_node "def foo\n1\nend", Def.new("foo", [], [1.int])
  it_parses_single_node "def downto(n)\n1\nend", Def.new("downto", ["n".var], [1.int])
  it_parses_single_node "def foo ; 1 ; end", Def.new("foo", [], [1.int])
  it_parses_single_node "def foo; end", Def.new("foo", [], nil)
  it_parses_single_node "def foo(var); end", Def.new("foo", ["var".var], nil)
  it_parses_single_node "def foo(\nvar); end", Def.new("foo", ["var".var], nil)
  it_parses_single_node "def foo(\nvar\n); end", Def.new("foo", ["var".var], nil)
  it_parses_single_node "def foo(var1, var2); end", Def.new("foo", ["var1".var, "var2".var], nil)
  it_parses_single_node "def foo(\nvar1\n,\nvar2\n)\n end", Def.new("foo", ["var1".var, "var2".var], nil)
  it_parses_single_node "def foo var; end", Def.new("foo", ["var".var], nil)
  it_parses_single_node "def foo var\n end", Def.new("foo", ["var".var], nil)
  it_parses_single_node "def foo var1, var2\n end", Def.new("foo", ["var1".var, "var2".var], nil)
  it_parses_single_node "def foo var1,\nvar2\n end", Def.new("foo", ["var1".var, "var2".var], nil)
  it_parses_single_node "def foo; 1; 2; end", Def.new("foo", [], [1.int, 2.int])
  # it_parses_single_node "def foo(n); foo(n -1); end", Def.new("foo", ["n".var], "foo".call(Call.new("n".var, :-, [1.int])))

  it_parses_single_node "def foo; a; end", Def.new('foo', [], ["a".call])
  it_parses_single_node "def foo(a); a; end", Def.new('foo', ['a'.var], ["a".var])
  it_parses_single_node "def foo; a = 1; a; end", Def.new('foo', [], [Assign.new('a'.var, 1.int), 'a'.var])

  it_parses_single_node "foo", "foo".call
  it_parses_single_node "foo()", "foo".call
  it_parses_single_node "foo(1)", "foo".call(1.int)
  it_parses_single_node "foo 1", "foo".call(1.int)
  it_parses_single_node "foo 1\n", "foo".call(1.int)
  it_parses_single_node "foo 1;", "foo".call(1.int)
  it_parses_single_node "foo 1, 2", "foo".call(1.int, 2.int)
  it_parses_single_node "foo (1 + 2), 3", "foo".call(Call.new(1.int, :"+", [2.int]), 3.int)
  it_parses_single_node "foo(1 + 2)", "foo".call(Call.new(1.int, :"+", [2.int]))
  it_parses_single_node "foo -1.0, -2.0", "foo".call(-1.float, -2.float)

  it_parses_single_node "foo + 1", Call.new("foo".call, :"+", [1.int])
  it_parses_single_node "foo +1", Call.new(nil, "foo", [1.int])
  # it_parses "foo = 1; foo +1", [Assign.new("foo".var, 1.int), Call.new("foo".var, :+, [1.int])]
  # it_parses "foo = 1; foo -1", [Assign.new("foo".var, 1.int), Call.new("foo".var, :-, [1.int])]

  ["=", "<", "<=", "==", "!=", ">", ">=", "+", "-", "*", "/"].each do |op|
    it_parses_single_node "def #{op}; end;", Def.new(op.to_sym, [], nil)
  end

  ['<', '<=', '==', '>', '>=', '+', '-', '*', '/'].each do |op|
    it_parses_single_node "1 #{op} 2", Call.new(1.int, op.to_sym, [2.int])
    it_parses_single_node "n #{op} 2", Call.new("n".call, op.to_sym, [2.int])
  end

  [:'+'].each do |op|
    it_parses_single_node "a #{op}= 1", Assign.new("a".var, Call.new("a".var, op.to_sym, [1.int]))
  end

  it_parses_single_node "if foo; 1; end", If.new("foo".call, 1.int)
  it_parses_single_node "if foo\n1\nend", If.new("foo".call, 1.int)
  it_parses_single_node "if foo; 1; else; 2; end", If.new("foo".call, 1.int, 2.int)
  it_parses_single_node "if foo\n1\nelse\n2\nend", If.new("foo".call, 1.int, 2.int)
  it_parses_single_node "if foo; 1; elsif bar; 2; else 3; end", If.new("foo".call, 1.int, If.new("bar".call, 2.int, 3.int))

  it_parses_single_node "while true; 1; end;", While.new(true.bool, 1.int)

  it_parses_single_node "self", "self".var
end
