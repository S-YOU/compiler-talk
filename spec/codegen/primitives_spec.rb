require 'spec_helper'

describe 'Code gen: primitives' do
  it 'codegens bool' do
    run('true').to_b.should be true
  end

  it 'codegens int' do
    run('1').to_i.should eq(1)
  end

  it 'codegens float' do
    run('1; 2.5').to_f.should eq(2.5)
  end

  it 'codegens char' do
    run("'a'").to_i.should eq(?a.ord)
  end

  it "codegens Bool && Bool -> true" do
    run('true && true').to_b.should be true
  end

  it "codegens Bool && Bool -> false" do
    run('true && false').to_b.should be false
  end

  it "codegens Bool || Bool -> false" do
    run('false || false').to_b.should be false
  end

  it "codegens Bool || Bool -> true" do
    run('false || true').to_b.should be true
  end

  it 'codegens Int + Int' do
    run('1 + 2').to_i.should eq(3)
  end

  it 'codegens Int - Int' do
    run('1 - 2').to_i.should eq(-1)
  end

  it 'codegens Int * Int' do
    run('2 * 3').to_i.should eq(6)
  end

  it 'codegens Int / Int' do
    run('7 / 3').to_i.should eq(2)
  end

  it 'codegens Int + Float' do
    run('1 + 1.5').to_f.should eq(2.5)
  end

  it 'codegens Int - Float' do
    run('3 - 0.5').to_f.should eq(2.5)
  end

  it 'codegens Int * Float' do
    run('2 * 1.25').to_f.should eq(2.5)
  end

  it 'codegens Int / Float' do
    run('5 / 2.0').to_f.should eq(2.5)
  end

  it 'codegens Float + Float' do
    run('1.0 + 1.5').to_f.should eq(2.5)
  end

  it 'codegens Float - Float' do
    run('3.0 - 0.5').to_f.should eq(2.5)
  end

  it 'codegens Float * Float' do
    run('2.0 * 1.25').to_f.should eq(2.5)
  end

  it 'codegens Float / Float' do
    run('5.0 / 2.0').to_f.should eq(2.5)
  end

  it 'codegens Float + Int' do
    run('1.5 + 1').to_f.should eq(2.5)
  end

  it 'codegens Float - Int' do
    run('3.5 - 1').to_f.should eq(2.5)
  end

  it 'codegens Float * Int' do
    run('1.25 * 2').to_f.should eq(2.5)
  end

  it 'codegens Float / Int' do
    run('5.0 / 2').to_f.should eq(2.5)
  end

  [['Int', ''], ['Float', '.0']].each do |type1, suffix1|
    [['Int', ''], ['Float', '.0']].each do |type2, suffix2|
      it 'codegens #{type1} == #{type2} gives false' do
        run("1#{suffix1} == 2#{suffix2}").to_b.should eq(false)
      end

      it 'codegens #{type1} == #{type2} gives true' do
        run("1#{suffix1} == 1#{suffix2}").to_b.should eq(true)
      end

      it 'codegens #{type1} != #{type2} gives false' do
        run("1#{suffix1} != 1#{suffix2}").to_b.should eq(false)
      end

      it 'codegens #{type1} != #{type2} gives true' do
        run("1#{suffix1} != 2#{suffix2}").to_b.should eq(true)
      end

      it 'codegens #{type1} < #{type2} gives false' do
        run("2#{suffix1} < 1#{suffix2}").to_b.should eq(false)
      end

      it 'codegens #{type1} < #{type2} gives true' do
        run("1#{suffix1} < 2#{suffix2}").to_b.should eq(true)
      end

      it 'codegens #{type1} <= #{type2} gives false' do
        run("2#{suffix1} <= 1#{suffix2}").to_b.should eq(false)
      end

      it 'codegens #{type1} <= #{type2} gives true' do
        run("1#{suffix1} <= 1#{suffix2}").to_b.should eq(true)
        run("1#{suffix1} <= 2#{suffix2}").to_b.should eq(true)
      end

      it 'codegens #{type1} > #{type2} gives false' do
        run("1#{suffix1} > 2#{suffix2}").to_b.should eq(false)
      end

      it 'codegens #{type1} > #{type2} gives true' do
        run("2#{suffix1} > 1#{suffix2}").to_b.should eq(true)
      end

      it 'codegens #{type1} >= #{type2} gives false' do
        run("1#{suffix1} >= 2#{suffix2}").to_b.should eq(false)
      end

      it 'codegens #{type1} >= #{type2} gives true' do
        run("1#{suffix1} >= 1#{suffix2}").to_b.should eq(true)
        run("2#{suffix1} >= 1#{suffix2}").to_b.should eq(true)
      end
    end
  end
end
