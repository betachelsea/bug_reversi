# frozen_string_literal: true

require_relative './position'

WHITE_STONE = 1
BLACK_STONE = 2
BLANK_CELL = 0

DEBUG_STONES = %w[
  blank_cell
  white_stone
  black_stone
].freeze

# チェスボードを参考として、マスを 'a8', 'd6' と書いて表現する。
# 変数名cellstrとして取り扱う。
ROW = %w[a b c d e f g h].freeze
COL = %w[8 7 6 5 4 3 2 1].freeze

DIRECTIONS = [
  DIRECTION_TOP_LEFT      = :top_left,
  DIRECTION_TOP           = :top,
  DIRECTION_TOP_RIGHT     = :top_right,
  DIRECTION_LEFT          = :left,
  DIRECTION_RIGHT         = :right,
  DIRECTION_BOTTOM_LEFT   = :bottom_left,
  DIRECTION_BOTTOM        = :bottom,
  DIRECTION_BOTTOM_RIGHT  = :bottom_right
].freeze

def output(board)
  puts "  #{ROW.join(' ')}"
  board.each.with_index do |row, i|
    print COL[i].to_s
    row.each do |cell|
      case cell
      when WHITE_STONE then print ' ○'
      when BLACK_STONE then print ' ●'
      else print ' -'
      end
    end
    print "\n"
  end
end

def copy_board(to_board, from_board)
  from_board.each.with_index do |col, col_i|
    col.each.with_index do |cell, row_j|
      to_board[col_i][row_j] = cell
    end
  end
end

def put_stone!(board, cellstr, stone_color, execute = true) # rubocop:disable Style/OptionalBooleanParameter
  pos = Position.new(cellstr: cellstr)
  raise '無効なポジションです' if pos.invalid?
  raise 'すでに石が置かれています' unless board[pos.col][pos.row] == BLANK_CELL

  # 盤面コピー・仮配置
  copied_board = Marshal.load(Marshal.dump(board))
  copied_board[pos.col][pos.row] = stone_color

  turn_succeed = false
  DIRECTIONS.each do |direction|
    next_pos = pos.next_position(direction)
    next_pos_color = pos_stone_color(copied_board, next_pos.row, next_pos.col)
    next if next_pos_color == stone_color

    turn_succeed = true if turn!(copied_board, next_pos, stone_color, direction)
  end

  copy_board(board, copied_board) if execute && turn_succeed

  turn_succeed
end

# target_posはひっくり返す対象セル
def turn!(board, target_pos, attack_stone_color, direction)
  return false if target_pos.out_of_board?
  return false if pos_stone_color(board, target_pos.row, target_pos.col) == BLANK_CELL

  next_pos = target_pos.next_position(direction)
  next_stone = pos_stone_color(board, next_pos.row, next_pos.col)

  if next_stone == attack_stone_color
    board[target_pos.col][target_pos.row] = attack_stone_color
    true

  elsif turn!(board, next_pos, attack_stone_color, direction)
    board[target_pos.col][target_pos.row] = attack_stone_color
    true

  else
    false
  end
end

def pos_stone_color(board, row, col)
  return nil unless (0..7).cover?(row) && (0..7).cover?(col)

  board[col][row]
end

def finished?(board)
  return true unless board.flatten.uniq.include?(BLANK_CELL)
  return false if placeable?(board, WHITE_STONE)
  return false if placeable?(board, BLACK_STONE)
  true # 白黒どちらも配置不可
end

def placeable?(board, attack_stone_color)
  board.each.with_index do |cols, col|
    cols.each.with_index do |cell, row|
      next unless cell == BLANK_CELL # 空セルでなければ判定skip

      position = Position.new(row: row, col: col)
      return true if put_stone!(board, position.to_cellstr, attack_stone_color, false)
    end
  end
  false
end

def count_stone(board, stone_color)
  board.flatten.count { |n| n == stone_color }
end

class Position
  attr_accessor :row, :col

  def initialize(cellstr: nil, row: nil, col: nil)
    if cellstr
      @row = ROW.index(cellstr[0])
      @col = COL.index(cellstr[1])
    else
      @row = row
      @col = col
    end
  end

  def invalid?
    row.nil? || col.nil?
  end

  def out_of_board?
    !((0..7).cover?(row) && (0..7).cover?(col))
  end

  def to_cellstr
    "#{ROW[row]}#{COL[col]}"
  end

  def next_position(direction)
    case direction
    when DIRECTION_TOP_LEFT     then Position.new(row: row - 1, col: col - 1)
    when DIRECTION_TOP          then Position.new(row: row, col: col - 1)
    when DIRECTION_TOP_RIGHT    then Position.new(row: row + 1, col: col - 1)
    when DIRECTION_LEFT         then Position.new(row: row - 1, col: col)
    when DIRECTION_RIGHT        then Position.new(row: row + 1, col: col)
    when DIRECTION_BOTTOM_LEFT  then Position.new(row: row - 1, col: col + 1)
    when DIRECTION_BOTTOM       then Position.new(row: row, col: col + 1)
    when DIRECTION_BOTTOM_RIGHT then Position.new(row: row + 1, col: col + 1)
    else raise 'Unknown direction'
    end
  end
end
