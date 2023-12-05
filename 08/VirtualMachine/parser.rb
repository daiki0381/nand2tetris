# frozen_string_literal: true

class Parser
  attr_reader :command

  COMMAND_TYPE = {
    'push' => 'C_PUSH',
    'pop' => 'C_POP',
    'label' => 'C_LABEL',
    'goto' => 'C_GOTO',
    'if' => 'C_IF',
    'function' => 'C_FUNCTION',
    'return' => 'C_RETURN',
    'call' => 'C_CALL'
  }.freeze

  def initialize(file)
    @file = File.open(file)
    @command = nil
  end

  def has_more_commands?
    !@file.eof?
  end

  def advance
    @command = @file.readline.gsub(%r|\s*//.+|, '').strip.split(' ')
  end

  def command_type
    COMMAND_TYPE[@command[0]] || 'C_ARITHMETIC'
  end

  def arg1
    return if command_type == 'C_RETURN'

    if command_type == 'C_ARITHMETIC' then
      @command[0]
    else
      @command[1]
    end
  end

  def arg2
    return unless %w(C_PUSH C_POP C_FUNCTION C_CALL).include?(command_type)

    command[2]
  end
end
