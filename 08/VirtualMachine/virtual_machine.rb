# !/usr/bin/env ruby
# frozen_string_literal: true

require_relative './code_writer'
require_relative './parser'

class VirtualMachine
  def execute
    path = ARGV[0]
    if path.end_with?('.vm') then
      code_writer = CodeWriter.new(path.gsub(/\.vm$/, '.asm'))
      translate_file(path, code_writer)
    else
      dir = path.end_with?('/') ? path[..-2] : path
      code_writer = CodeWriter.new("#{dir}/#{File.basename(dir)}.asm")

      if Dir.entries(dir).any? {|file| File.basename(file) == 'Sys.vm' }
        code_writer.write_init
      end

      Dir.foreach(dir) do |file|
        next unless File.extname(file) == '.vm' && !File.basename(file).include?('._')
        file_path = "#{dir}/#{file}"
        translate_file(file_path, code_writer)        
      end
    end
    
    code_writer.close
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
      when 'C_LABEL' then
        code_writer.write_label(parser.arg1)
      when 'C_GOTO' then
        code_writer.write_goto(parser.arg1)
      when 'C_IF' then
        code_writer.write_if(parser.arg1)
      when 'C_FUNCTION' then
        code_writer.write_function(parser.arg1, parser.arg2)
      when 'C_RETURN' then
        code_writer.write_return
      when 'C_CALL' then
        code_writer.write_call(parser.arg1, parser.arg2)
      end
    end

    parser.close
  end
end

VirtualMachine.new.execute
