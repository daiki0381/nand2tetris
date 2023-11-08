# !/usr/bin/env ruby
# frozen_string_literal: true

require_relative './code'
require_relative './parser'
require_relative './symbol_table'

class Assembler
  def initialize
    @address = 0
    @variable_address = 16
    @symbol_table = SymbolTable.new
  end

  def execute
    file = ARGV[0]

    return if file.nil?

    File.open(file) do |asm_file|
      first_lap(asm_file)
      dir_name = File.dirname(file)
      file_name = "#{File.basename(file, '.asm')}"
      output_file = File.join(dir_name, "#{file_name}.hack")
      asm_file.seek(0, IO::SEEK_SET)
      second_lap(asm_file, output_file) 
    end
  end

  private

  def first_lap(file)
    parser = Parser.new(file)
    while parser.has_more_commands?
      parser.advance

      next if parser.command.empty?

      case parser.command_type
      when 'A_COMMAND', 'C_COMMAND'
        @address += 1
      when 'L_COMMAND'
        @symbol_table.add_entry(parser.symbol, @address)
      end
    end
  end

  def second_lap(file, output_file)
    File.open(output_file, 'w') do |hack_file|
      parser = Parser.new(file)
      while parser.has_more_commands?
        parser.advance

        next if parser.command.empty?

        row =
          case parser.command_type
          when 'A_COMMAND'
            a_command_binary_code(parser)
          when 'C_COMMAND'
            c_command_binary_code(parser)
          end

        next if row.nil?

        hack_file.write("#{row}\n")
      end
    end
  end

  def a_command_binary_code(parser)
    symbol =
      if @symbol_table.contains?(parser.symbol) then
        @symbol_table.get_address(parser.symbol)
      elsif parser.symbol == parser.symbol.to_i.to_s then # numeric symbol
        parser.symbol
      else # variable symbol
        @symbol_table.add_entry(parser.symbol, @variable_address)
        @variable_address += 1
        @symbol_table.get_address(parser.symbol)
      end
    symbol.to_i.to_s(2).rjust(16, '0')
  end

  def c_command_binary_code(parser)
    comp_mnemonic = parser.comp_mnemonic
    dest_mnemonic = parser.dest_mnemonic
    jump_mnemonic = parser.jump_mnemonic
    "111#{comp_binary_code(comp_mnemonic)}#{dest_binary_code(dest_mnemonic)}#{jump_binary_code(jump_mnemonic)}"
  end
end

Assembler.new.execute
