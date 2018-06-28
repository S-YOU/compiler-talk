require 'llvm/core'
require 'llvm/execution_engine'

HELLO_STRING = "Hello, World!"

mod = LLVM::Module.new('hello')

hello = mod.globals.add(LLVM::ConstantArray.string(HELLO_STRING), :hello) do |v|
  v.global_constant = true
  v.initializer = LLVM::ConstantArray.string(HELLO_STRING)
end

cputs = mod.functions.add('puts', [LLVM.Pointer(LLVM::Int8)], LLVM::Int32)

main = mod.functions.add('main', [], LLVM::Int32) do |function|
  function.basic_blocks.append.build do |b|
    zero = LLVM.Int(0)

    var1 = b.gep hello, [zero, zero]

    b.call cputs, var1
    b.ret zero
  end
end

mod.dump

puts "------------------------------"

LLVM.init_jit

engine = LLVM::JITCompiler.new(mod)
engine.run_function(main)
engine.dispose
