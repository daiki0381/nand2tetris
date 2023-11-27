# frozen_string_literal: true

class CodeWriter
  REGISTER_SEGMENTS = {
    'local' => 'LCL',
    'argument' => 'ARG',
    'this' => 'THIS',
    'that' => 'THAT'
  }.freeze

  ADDRESS_SEGMENTS = {
    'pointer' => 3,
    'temp' => 5    
  }.freeze

  def initialize(file)
    @file = File.open(file, 'w')
    @symbol_num = 0
  end

  def set_file_name(file_name)
    @ffile_name = File.basename(file_name, '.vm')
  end

  def write_push(_command_type, segment, index)
    if segment == 'constant' then
      write_codes([
        "@#{index}",
        'D=A'
      ])
      write_push_from_d_register
    elsif REGISTER_SEGMENTS.keys.include?(segment) then
      write_push_from_register_segment(segment, index)
    elsif ADDRESS_SEGMENTS.keys.include?(segment) then
      write_push_from_address_segment(segment, index)
    elsif segment == 'static' then
      write_codes([
        "@#{@file_name}.#{index}",
        'D=M'
      ])
      write_push_from_d_register
    end
  end

  def write_pop(command_type, segment, index)
    if REGISTER_SEGMENTS.keys.include?(segment) then
      write_pop_to_register_segment(segment, index)
    elsif ADDRESS_SEGMENTS.keys.include?(segment) then
      write_pop_to_address_segment(segment, index)
    elsif segment == 'static' then
      write_pop_to_a_register
      write_codes([
        'D=M',
        "@#{@file_name}.#{index}",
        'M=D'
      ])
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

  def write_push_from_register_segment(segment, index)
    base_address = REGISTER_SEGMENTS[segment]

    write_codes([
      "@#{base_address}",
      'A=M'
    ])
    index.to_i.times do
      write_code('A=A+1')
    end
    write_code('D=M')
    write_push_from_d_register
  end

  def write_pop_to_register_segment(segment, index)
    base_address = REGISTER_SEGMENTS[segment]

    write_pop_to_a_register
    write_codes([
      'D=M',
      "@#{base_address}"
    ])
    index.to_i.times do
      write_code('A=A+1')
    end
    write_code('M=D')
  end

  def write_push_from_address_segment(segment, index)
    base_address = ADDRESS_SEGMENTS[segment]

    write_code("@#{base_address}")
    index.to_i.times do
      write_code('A=A+1')
    end
    write_code('D=M')
    write_push_from_d_register
  end
  
  def write_pop_to_address_segment(segment, index)
    base_address = ADDRESS_SEGMENTS[segment]

    write_pop_to_a_register
    write_codes([
      'D=M',
      "@#{base_address}"
    ])
    index.to_i.times do
      write_code('A=A+1')
    end
    write_code('M=D')
  end

  def symbol
    @symbol_num += 1
    "SYMBOL#{@symbol_num}"
  end
end
