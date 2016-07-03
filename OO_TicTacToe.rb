require 'pry'

module Talkable
  # Mix-in to format narrator text
  def prompt(message)
    puts "=> #{message}"
  end
end

module Clearable
  def clear
    system 'clear'
  end
end

class Player
  include Talkable

  attr_accessor :name, :board, :symbol, :wins

  def to_s
    name
  end
end

class Human < Player
  def initialize(board)
    prompt "what is your name? "
    @name = gets.chomp
    @board = board
    @wins = 0
    prompt "What is your marker symbol?"
    temp = gets.chomp
    if temp.length != 1
      prompt "Please enter a single character."
    else
      @symbol = temp
    end
  end

  def take_turn
    square_to_mark = nil
    available_squares = board.empty_square_keys
    loop do
      prompt "Where do you want to place your mark #{name}?"
      prompt "Your choices are: #{joinor(available_squares)}"
      square_to_mark = gets.chomp.to_i
      break if available_squares.include?(square_to_mark)
      prompt "Enter a valid square #{joinor(available_squares)}"
    end
    # refactor to reduce method chain, add square to mark method to board
    board.squares[square_to_mark].update!(self)
  end

  def joinor(arr, delimiter=', ', end_of_list_word='or')
    arr = arr.clone
    arr[-1]  = "#{end_of_list_word} #{arr.last}" if arr.size > 1
    arr.join(delimiter)
  end
end

class Computer < Player
  SYMBOL = 'O'
  PERSONALITIES = [:Terminator, :SALLY, :SugarBot]

  def initialize(board)
    @board = board
    @symbol = SYMBOL
    @name = PERSONALITIES.sample
    @wins = 0
  end

  def take_turn
    square_to_mark = nil
    Board::WINNING_LINES.each do |line|
      square_to_mark = find_at_risk_square(line)
      break if square_to_mark
    end

    if !square_to_mark 
      square_to_mark = board.empty_square_keys.sample
    end

    board.squares[square_to_mark].update!(self)
  end

  # known bug for when there is all symbols and no blank line !!!
  def find_at_risk_square(line)
    marks = []
    line.each do |key|
      marks.push(board.square_at(key).marker)
    end

    return nil if marks.count(' ') > 1

    only_symbols = marks.select{|key| key != ' '}

    if only_symbols.count(only_symbols.first) == 2
      binding.pry
      return line[marks.index(' ')]
    end

    return nil
  end
end

class Board
  INITIAL_MARKER = ' '
  WINNING_LINES =  [[1, 2, 3], [4, 5, 6], [7, 8, 9] + # rows
                    [1, 4, 7], [2, 5, 8], [3, 6, 9] + # cols
                    [1, 5, 9], [3, 5, 7]]             # diagonals

  attr_accessor :squares

  def initialize
    @squares = {}
    reset
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  def draw
    puts "
                 |     |
              #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}
                 |     |
            =================
                 |     |
              #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}
                 |     |
            =================
                 |     |
              #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}
                 |     |
         "
  end

  def square_at(key)
    @squares[key]
  end

  def empty_square_keys
    empty_squares_keys = []
    squares.each do |key, _|
      empty_squares_keys.push(key) if squares[key].to_s == INITIAL_MARKER
    end
    empty_squares_keys
  end

  def empty_square?(square)
    square.marker == INITIAL_MARKER
  end

  def winner?
    !!detect_winner
  end

  def detect_winner
    WINNING_LINES.each do |line|
      if @squares[line[0]].marker == @squares[line[1]].marker &&
         @squares[line[0]].marker == @squares[line[2]].marker &&
         @squares[line[0]].marker != INITIAL_MARKER
        return @squares[line[0]].marker
      end
    end
    nil
  end

  def full?
    empty_square_keys.empty?
  end
end

class Square
  attr_accessor :marker

  def initialize
    @marker = ' '
  end

  def update!(player)
    @marker = player.symbol
  end

  def to_s
    @marker
  end
end

class GameEngine
  include Talkable

  attr_reader :human, :computer, :board, :wins_to_win

  def initialize
    @board = Board.new
    @human = Human.new(board)
    @computer = Computer.new(board)
    @current_player = [@human, @computer].sample
    @human == @current_player ? @next_player = @computer : @next_player = @human
    @wins_to_win = 2
  end

  def play
    display_welcome
    loop do
      display_board
      loop do
        current_player_turn
        break if board.winner? || board.full?
      end
      display_match_result
      break if !!ultimate_victor
      display_scoreboard
      play_again?
      board.reset
    end
    prompt "#{ultimate_victor} is the ultimate victor!!!"
    display_goodbye
  end

  private

  def clear
    system 'clear'
  end

  def display_welcome
    prompt("Hello and welcome to Tic Tac Toe!")
  end

  def display_board
    clear
    puts "#{human.name} is #{human.symbol}. #{computer.name} is #{computer.symbol}"
    board.draw
  end

  def display_match_result
    winner_name = determine_winner
    update_score(winner_name)

    if !!winner_name
      prompt "#{winner_name} is the winner!"
    else
      prompt "Match was a tie!"
    end

    prompt "First to #{wins_to_win} is the ultimate victor!"
  end

  def display_scoreboard
    prompt "Scoreboard: "
    prompt "#{human.name}: #{human.wins}"
    prompt "#{computer.name}: #{computer.wins}"
  end

  def display_goodbye
    prompt("Goodbye!")
  end

  def current_player_turn
    @current_player.take_turn
    display_board

    @current_player, @next_player = @next_player, @current_player
  end

  def determine_winner
    if human.symbol == board.detect_winner
      return human.name
    elsif computer.symbol == board.detect_winner
      return computer.name
    else
      return nil
    end
  end

  def update_score(winner_name)
    if winner_name == human.name
      human.wins += 1
    elsif winner_name == computer.name
      computer.wins += 1
    end
  end

  def play_again?
    loop do
      prompt "Ready to play again? (Y or N)"
      ans = gets.chomp.downcase
      if ans == 'y' then return true
      elsif ans == 'n' then return false
      end
    end
  end

  def ultimate_victor
    if human.wins >= wins_to_win
      human.name
    elsif computer.wins >= wins_to_win
      computer.name
    else
      nil
    end
  end
end
### GAME ###
game = GameEngine.new
game.play

# Refactor suggestions
# 2. Move all display logic to game GameEngine
# 3. Clean up interface
# 4. Print out usernames and moves each round
# 5. Label who the human and computer with what
# => symbol they use above the board
