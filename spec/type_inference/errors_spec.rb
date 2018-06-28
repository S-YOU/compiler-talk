require 'spec_helper'

describe 'Type inference: errors' do
  it "reports undefined local variable or method" do
    nodes = parse %(
def foo
  a = something
end

def bar
  foo
end

bar).strip

    lambda {
      type nodes
    }.should raise_error(Crystal::Exception, "
Error: undefined local variable or method 'something' in 'foo'
      ".strip)
  end

  it "reports undefined method" do
    nodes = parse "foo()"

    lambda {
      type nodes
    }.should raise_error(Crystal::Exception, /undefined local variable or method 'foo'/)
  end

  it "reports wrong number of arguments" do
    nodes = parse "def foo(x); x; end; foo"

    lambda {
      type nodes
    }.should raise_error(Crystal::Exception, regex("wrong number of arguments for 'foo' (0 for 1)"))
  end

  it "reports can't call primitive with args" do
    nodes = parse "1 + 'a'"

    lambda {
      type nodes
    }.should raise_error(Crystal::Exception, regex("can't call Int#+ with types [Char]"))
  end

  it "reports can't call external with args" do
    nodes = parse "putchar 1"

    lambda {
      type nodes
    }.should raise_error(Crystal::Exception, regex("can't call putchar with types [Int]"))
  end
end
