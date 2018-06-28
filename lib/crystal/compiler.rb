require 'llvm/transforms/ipo'
require 'llvm/transforms/scalar'

module Crystal
  class Compiler
    include Crystal

    attr_reader :command

    def initialize
      output_filename = File.basename(ARGV[0], File.extname(ARGV[0]))
      @command = "llc | clang -x assembler -o #{output_filename} -"
    end

    def compile
      begin
        mod = build ARGF.read
        engine = LLVM::JITCompiler.new mod
        optimize mod, engine
      rescue Crystal::Exception => ex
        puts ex.message
        exit 1
      rescue Exception => ex
        puts ex
        puts ex.backtrace
        exit 1
      end

      if @run
        engine.run_function mod.functions["main"]
      else
        reader, writer = IO.pipe
        Thread.new do
          mod.write_bitcode(writer)
          writer.close
        end

        pid = spawn command, in: reader
        Process.waitpid pid
      end
    end

    def optimize(mod, engine)
      pm = LLVM::PassManager.new engine
      pm.inline!
      pm.gdce!
      pm.instcombine!
      pm.reassociate!
      pm.gvn!
      pm.mem2reg!
      pm.simplifycfg!
      pm.tailcallelim!
      pm.loop_unroll!
      pm.loop_deletion!
      pm.loop_rotate!

      5.times { pm.run mod }
    end
  end
end
