# !/usr/bin/env ruby
# frozen_string_literal: true

require_relative './code_writer'
require_relative './parser'

class VirtualMachine
  def execute
    file = ARGV[0]
    if file.end_with?('.vm') then
      code_writer = CodeWriter.new(file.gsub(/\.vm$/, '.asm'))
      translate_file(file, code_writer)
    end
  end

  private

  def translate_file(file, code_writer)
    code_writer.set_file_name(file)
    parser = Parser.new(file)
    while parser.has_more_commands?
      parser.advance

      next if parser.command.empty?

      case parser.command_type
      when 'C_ARITHMETIC' then
        code_writer.write_aristhmetic(parser.arg1)
      when 'C_PUSH' then        
        code_writer.write_push(parser.command_type, parser.arg1, parser.arg2)
      when 'C_POP' then
        code_writer.write_pop(parser.command_type, parser.arg1, parser.arg2)        
      end
    end
    code_writer.close
  end
end

VirtualMachine.new.execute
