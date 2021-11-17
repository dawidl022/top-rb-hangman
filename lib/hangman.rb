require 'set'

def put_blank_line
  puts
end

module Validatable
  def input_option(message, options)
    valid_input = nil
    user_input = nil

    until valid_input
      if user_input
        puts "Invalid input. Please input one of the following:"
        puts "#{options.map { |option| "#{option.to_s}" }}"
        put_blank_line
      end

      print message
      user_input = gets.chomp.downcase.to_sym
      valid_input = user_input if options.include?(user_input)
    end

    valid_input
  end
end

class Menu
  DEFAULT_WORD_FILE = "5desk.txt"

  include Validatable

  def initialize(word_file, turns = 8, save_location = "save")
    @words = load_words(word_file || DEFAULT_WORD_FILE)
    @player = Player.new
    @save_location = save_location
    @game = Hangman.new(@player, @words, turns, save_location)
  end

  public

  def start
    puts logo
    main_menu
  end

  def main_menu
    options = [:new]

    if File.exist?(@save_location)
      options << :load
    end

    display_options = options.map { |option| "[#{option.to_s.capitalize}]" }
    puts display_options
    put_blank_line

    case input_option("", options)
    when :new then nil
    when :load then load_game
    else raise "Invalid argument"
    end

    @game.play_game
  end

  private

  def logo
    '
888    888
888    888
888    888
8888888888  8888b.  88888b.   .d88b.  88888b.d88b.   8888b.  88888b.
888    888     "88b 888 "88b d88P"88b 888 "888 "88b     "88b 888 "88b
888    888 .d888888 888  888 888  888 888  888  888 .d888888 888  888
888    888 888  888 888  888 Y88b 888 888  888  888 888  888 888  888
888    888 "Y888888 888  888  "Y88888 888  888  888 "Y888888 888  888
                                  888
                              Y8b d88P
                              "Y88P"
    '
  end

  def load_words(file)
    File.readlines(file, chomp: true)
  end

  def load_game
    @game = Marshal.load(File.read(@save_location))
  end

end

class Hangman
  CUE_TO_SAVE = "save"

  def initialize(player, words, total_turns, save_file)
    @player = player
    @word = words.select { |word| word.length >= 5 && word.length <= 12 }.sample
           .downcase
    @guessed_letters = Set.new
    @incorrect_letters = Set.new
    @turns_left = total_turns
    @save_file = save_file
  end

  public

  def play_game
    until game_over?
      display_game_hub

      letter = @player.take_guess(CUE_TO_SAVE).downcase

      if letter == CUE_TO_SAVE
        save_current_state
        puts "Game saved!\n"
      elsif @word.include?(letter)
        @guessed_letters << letter
      else
        @turns_left -= 1
        @incorrect_letters << letter
      end
      put_blank_line
    end


    if player_won?
      puts "Well done, you managed to guess the secret word!"
    else
      puts "Tough luck, the secret word was: #{@word}"
    end
  end

  private

  def display_game_hub
    puts "Incorrect letters: #{@incorrect_letters.join(", ")}".ljust(69) + \
         "Turns left: #{@turns_left}" + "\n\n"
    puts mask_word + "\n\n"
  end

  def save_current_state
    File.open(@save_file, 'w') do |file|
      file.write(Marshal.dump(self))
    end
  end

  def game_over?
    player_won? || @turns_left < 1
  end

  def player_won?
    @guessed_letters == @word.split("").to_set
  end

  def mask_word(mask_char = "_")
    @word.split("").map do |letter|
      if @guessed_letters.include?(letter)
        letter
      else
        mask_char
      end
    end.join(" ")
  end

end

class Player
  def take_guess(escape_word)
    puts "Enter a single letter to make a guess or type SAVE to save the " \
         "current game state:"
    guess = gets.chomp.downcase

    until guess == escape_word || guess.length == 1 && guess =~ /[a-z]/
      puts "You must enter exactly one letter. Try again:"
      guess = gets.chomp.downcase
    end

    guess
  end
end

if __FILE__ == $PROGRAM_NAME
  # TODO parse keyword args for output save file -o and turns -n
  Menu.new(ARGV[0]).start
end
