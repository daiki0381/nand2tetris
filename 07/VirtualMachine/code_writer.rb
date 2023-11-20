# frozen_string_literal: true

class CodeWriter
  def initialize(file)
    @file = File.open(file, 'w')
    @symbol_num = 0
  end

  def write_push_pop(command_type, segment, index)
    if command_type == 'C_PUSH' then
      if segment == 'constant' then
        write_codes([
          "@#{index}",
          'D=A'
        ])
        write_push_from_d_register
      end
    end
  end

  def write_aristhmetic(command)
    case command
    when 'add', 'sub', 'and', 'or' then
      write_binary_operation(command)
    when 'neg', 'not' then
      write_unary_operation(command)
    when 'eq', 'gt', 'lt' then
      write_comp_operation(command)
    end
  end

  def close
    @file.close
  end

  private

  def write_code(code)
    @file.write("#{code}\n")
  end

  def write_codes(codes)
    codes.each do |code|
      write_code(code)
    end
  end

  # Push stack
  def write_push_from_d_register
    write_codes([
      '@SP',
      'A=M',
      'M=D',
      '@SP',
      'M=M+1'
    ])
  end

  # Pop stack
  def write_pop_to_a_register
    write_codes([
      '@SP',
      'M=M-1',
      'A=M'
    ])
  end
  
  def write_binary_operation(command)
    write_pop_to_a_register
    write_code('D=M')
    write_pop_to_a_register
    case command
    when 'add' then
      write_code('D=D+M')
    when 'sub' then
      write_code('D=M-D')
    when 'and' then
      write_code('D=D&M')
    when 'or' then
      write_code('D=D|M')
    end
    write_push_from_d_register
  end

  def write_unary_operation(command)
    write_codes([
      '@SP',
      'A=M-1'
    ])
    case command
    when 'neg' then
      write_code('M=-M')
    when 'not' then
      write_code('M=!M')
    end
  end

   def write_comp_operation(command)
    write_pop_to_a_register
    write_code('D=M')
    write_pop_to_a_register
    true_symbol = symbol
    false_symbol = symbol

    case command
    when 'eq' then
      comp_mnemock = 'JEQ'
    when 'gt' then
      comp_mnemock = 'JGT'
    when 'lt' then
      comp_mnemock = 'JLT'
    end

    write_codes([
      'D=M-D',
      "@#{true_symbol}",
      "D;#{comp_mnemock}",
      'D=0',
      "@#{false_symbol}",
      '0;JMP',
      "(#{true_symbol})",
      'D=-1',
      "(#{false_symbol})"
    ])
    write_push_from_d_register
  end

  def symbol
    @symbol_num += 1
    "SYMBOL#{@symbol_num}"
  end
end
