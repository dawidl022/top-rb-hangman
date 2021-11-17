require 'stringio'
require_relative "../lib/hangman"

NULL = File.open(File::NULL, 'w')

RSpec.describe Hangman do
  DEFAULT_SAVE_FILE = "save"
  DEFAULT_WORDS = ["qaa", "c", "queen", "ebebeeeeeeeeeeee"]

  let(:player) { double('Player') }
  let(:game) { described_class.new(player, DEFAULT_WORDS, 8, DEFAULT_SAVE_FILE) }

  describe "selects a word upon initialisation" do
    it "that is between 5 and 12 characters" do
      expect(game.instance_variable_get("@word")).to eq("queen")
    end

    it "that is all lowercase" do
      words = ["HELLO"]
      game = described_class.new(player, words, 8, DEFAULT_SAVE_FILE)
      expect(game.instance_variable_get("@word")).to eq("hello")
    end
  end

  describe "#player_won?" do
    it "returns false when starting game" do
      expect(game.send(:player_won?)).to be false
    end

    it "returns false when some letters are guessed" do
      game.instance_variable_set(:@guessed_letters, Set.new(["q", "u", "n"]))
      expect(game.send(:player_won?)).to be false
    end

    it "returns true when all letters are guessed" do
      game.instance_variable_set(:@guessed_letters, Set.new(["q", "u", "n", "e"]))
      expect(game.send(:player_won?)).to be true
    end
  end

  describe "#mask_word" do
    it "is all underscores when no letters are guessed correctly" do
      expect(game.send(:mask_word)).to eq("_ _ _ _ _")
    end

    it "is still only underscores when only incorrect letters are guessed" do
      game.instance_variable_set(:@incorrect_letters, Set.new(["a", "b", "c"]))
      expect(game.send(:mask_word)).to eq("_ _ _ _ _")
    end

    it "shows the guessed letters in their correct positions" do
      game.instance_variable_set(:@guessed_letters, Set.new(["q", "u", "n"]))
      expect(game.send(:mask_word)).to eq("q u _ _ n")
    end

    it "shows the whole word when all letters are guessed correctly" do
      game.instance_variable_set(:@guessed_letters, Set.new(["q", "u", "e", "n"]))
      expect(game.send(:mask_word)).to eq("q u e e n")
    end
  end

  describe "#save_current_state" do
    clean_files = Proc.new do
      if File.exist?(DEFAULT_SAVE_FILE)
        File.delete(DEFAULT_SAVE_FILE)
      end
    end

    before(&clean_files)
    after(&clean_files)

    it "creates a save file" do
      game.send(:save_current_state)
      expect(File.exist?(DEFAULT_SAVE_FILE)).to be true
    end

    it "data saved to the file when deserialized gives object back" do
      game.send(:save_current_state)
      saved_data = File.read(DEFAULT_SAVE_FILE)

      expect(Marshal.load(saved_data).class).to eq(described_class)
    end
  end
end

RSpec.describe Player do
  let(:player) { described_class.new }
  save_cue = Hangman::CUE_TO_SAVE

  describe "#take_guess" do
    let(:input) { StringIO.new }
    before { $stdin = input }

    describe "returns" do
      before { $stdout = NULL }
      after { $stdout = STDOUT }

      it "the entered lowercase letter" do
        input.string = "b\n"
        expect(player.take_guess(save_cue)).to eq('b')
      end

      it "a lowercase letter when uppercase letter in entered" do
        input.string = "A\n"
        expect(player.take_guess(save_cue)).to eq('a')
      end

      it " and reprompts on invalid input" do
        input.string = "blah\nbla\nc"
        expect(player.take_guess(save_cue)).to eq('c')
      end

      it "when sentinel value is entered" do
        input.string = save_cue
        expect(player.take_guess(save_cue)).to eq(save_cue)
      end
    end
  end
end
