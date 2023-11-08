# frozen_string_literal: true

class Parser
  A_COMMAND_REGEXP = /@([0-9a-zA-Z_\.\$:]+)/
  L_COMMAND_REGEXP = /\(([0-9a-zA-Z_\.\$:]+)\)/
  C_COMMAND_REGEXP = /(?:(A?M?D?)=)?([^;]+)(?:;(.+))?/

  attr_reader :command
  
  def initialize(file)
    @file = file
    @command = nil
  end

  def has_more_commands?
    !@file.eof?
  end

  def advance
    @command = @file.readline.gsub(%r|\s*//.+|, '').strip
  end

  def command_type
    if @command[0] == '@' then
      'A_COMMAND'
    elsif @command[0] == '(' then
      'L_COMMAND'
    else
      'C_COMMAND'
    end
  end

  def symbol
    if command_type == 'A_COMMAND' then
      a_command_mnemonic = A_COMMAND_REGEXP.match(@command)
      if a_command_mnemonic.nil? then
        raise 'Failed to parse a_command_mnemonic'
      end
      a_command_mnemonic[1]
    elsif command_type == 'L_COMMAND' then
      l_command_mnemonic = L_COMMAND_REGEXP.match(@command)
      if l_command_mnemonic.nil? then
        raise 'Failed to parse l_command_mnemonic'
      end
      l_command_mnemonic[1]
    else
      raise 'command_type is not A_COMMAND or L_COMMAND'
    end
  end

  def dest_mnemonic
    if command_type == 'C_COMMAND' then
       c_command_mnemonic = C_COMMAND_REGEXP.match(@command)
      if c_command_mnemonic.nil? then
        raise 'Failed to parse c_command_mnemonic'
      end
      c_command_mnemonic[1]
    else
      raise 'command_type is not C_COMMAND'
    end
  end

  def comp_mnemonic
    if command_type == 'C_COMMAND' then
       c_command_mnemonic = C_COMMAND_REGEXP.match(@command)
      if c_command_mnemonic.nil? then
        raise 'Failed to parse c_command_mnemonic'
      end
      c_command_mnemonic[2]
    else
      raise 'command_type is not C_COMMAND'
    end
  end

  def jump_mnemonic
    if command_type == 'C_COMMAND' then
       c_command_mnemonic = C_COMMAND_REGEXP.match(@command)
      if c_command_mnemonic.nil? then
        raise 'Failed to parse c_command_mnemonic'
      end
      c_command_mnemonic[3]
    else
      raise 'command_type is not C_COMMAND'
    end
  end
end
