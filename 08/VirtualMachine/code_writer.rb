# frozen_string_literal: true

class CodeWriter
  REFERENCED_SEGMENTS = {
    'local' => 'LCL',
    'argument' => 'ARG',
    'this' => 'THIS',
    'that' => 'THAT'
  }.freeze

  STATIC_SEGMENTS = {
    'pointer' => 3,
    'temp' => 5    
  }.freeze

  BASE_ADDRESSES = %w(LCL ARG THIS THAT).freeze

  def initialize(file)
    @file = File.open(file, 'w')
    @symbol_num = 0
    @return_label_num = 0
  end

  def set_file_name(file_name)
    @ffile_name = File.basename(file_name, '.vm')
  end

  def write_init
    write_codes([
      '@256',
      'D=A',
      '@SP',
      'M=D'
    ])
    write_call('Sys.init', 0)
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
  
  def write_push(_command_type, segment, index)
    if segment == 'constant' then
      write_codes([
        "@#{index}",
        'D=A'
      ])
      write_push_from_d_register
    elsif REFERENCED_SEGMENTS.keys.include?(segment) then
      write_push_from_register_segment(segment, index)
    elsif STATIC_SEGMENTS.keys.include?(segment) then
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
    if REFERENCED_SEGMENTS.keys.include?(segment) then
      write_pop_to_register_segment(segment, index)
    elsif STATIC_SEGMENTS.keys.include?(segment) then
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

  def write_label(label)
    write_code("(#{label})")
  end

  def write_goto(label)
    write_codes([
      "@#{label}",
      '0;JMP'
    ])
  end

  def write_if(label)
    write_pop_to_a_register
    write_codes([
      'D=M',
      "@#{label}",
      'D;JNE'
    ])
  end

  def write_function(function_name, arg_num)
    write_codes([
      "(#{function_name})",
      'D=0'
    ])

    arg_num.to_i.times do
      write_push_from_d_register
    end
  end
  
  def write_call(function_name, arg_num)
    label = return_label

    # push return-address
    write_codes([
      "@#{label}",
      'D=A'
    ])
    write_push_from_d_register
    
    # push LCL
    # push ARG
    # push THIS
    # push THAT
    BASE_ADDRESSES.each do |address|
      write_codes([
        "@#{address}",
        'D=M'
      ])
      write_push_from_d_register
    end

    # ARG = SP - n -5
    # LCL = SP
    write_codes([
      "@#{arg_num}",
      'D=A',
      '@5',
      'D=D+A',
      '@SP',
      'D=M-D',
      '@ARG',
      'M=D',
      '@SP',
      'D=M',
      '@LCL',
      'M=D'
    ])

    # goto f
    # declare label (return-address)
    write_codes([
      "@#{function_name}",
      '0;JMP',
      "(#{label})"
    ])
  end

  def write_return
    # FRAME (R13) = LCL
    # return-address (R14) = FRAME (R13) - 5
    # ARG = SP - 1
    # SP = ARG + 1
    write_codes([
      "@LCL",
      'D=M',
      '@R13',
      'M=D',
      '@5',
      'A=D-A',
      'D=M',
      '@R14',
      'M=D',
      '@SP',
      'A=M-1',
      'D=M',
      '@ARG',
      'A=M',
      'M=D',
      '@ARG',
      'D=M+1',
      '@SP',
      'M=D'
    ])

    # THAT = FRAME (R13) - 1
    # THIS = FRAME (R13) - 2
    # ARG = FRAME (R13) - 3
    # LCL = FRAME (R13) - 4
    BASE_ADDRESSES.reverse.each do |address|      
      write_codes([
       '@R13',
       'D=M-1',
       'A=D',
       'D=M',
       "@#{address}",
       'M=D'
      ])
    end

    # goto return-address (R14)
    write_codes([
      '@14',
      'A=M',
      '0;JMP'
    ])
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
    base_address = REFERENCED_SEGMENTS[segment]

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
    base_address = REFERENCED_SEGMENTS[segment]

    write_pop_to_a_register
    write_codes([
      'D=M',
      "@#{base_address}",
      'A=M'
    ])
    index.to_i.times do
      write_code('A=A+1')
    end
    write_code('M=D')
  end

  def write_push_from_address_segment(segment, index)
    base_address = STATIC_SEGMENTS[segment]

    write_code("@#{base_address}")
    index.to_i.times do
      write_code('A=A+1')
    end
    write_code('D=M')
    write_push_from_d_register
  end
  
  def write_pop_to_address_segment(segment, index)
    base_address = STATIC_SEGMENTS[segment]

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

  def return_label
    @return_label_num += 1
    "RETURN_LABEL#{@return_label_num}"
  end
end
