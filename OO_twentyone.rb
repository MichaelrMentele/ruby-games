require 'pry'

module Promptable
  def prompt(message)
    puts ">>> #{message}"
  end
end

class Participant
  include Promptable

  attr_reader :hand, :deck

  def initialize(deck)
    @hand = []
    @deck = deck
  end

  def hit
    @hand.push(@deck.deal_card)
  end

  def busted?
    total > 21
  end

  # does not take care of the ace case
  def total
    val = 0
    @hand.each do |card|
      val += card.last[0]
    end
    val
  end

  def format_hand
    formatted_hand = []
    hand.each do |card|
      formatted_hand.push(card[0] + card[1])
    end
    formatted_hand.join(', ')
  end
end

class Gambler < Participant
  def take_turn
    until busted?
      prompt "Your hand total is #{total}."
      prompt "Hit or Stay?"
      ans = gets.chomp.downcase
      if ans == 'hit'
        hit
      elsif ans == 'stay'
        prompt "The safe choice."
        break
      end
    end
  end
end

class Dealer < Participant
  def take_turn
    prompt "Dealers turn..."
    prompt "Dealer flops his second card..."
    prompt "Dealer shows #{format_hand}"
    while total < 17
      hit
      prompt "Dealer hits!"
      prompt "#{format_hand} for a total of #{total}"
    end
  end

  def reveal_card
    hand[0][0] + hand[0][1]
  end
end

class Deck
  SUITS = ['S', 'C', 'D', 'H']
  FACES = {
            'A' => [1, 11],
            '2' => [2],
            '3' => [3],
            '4' => [4],
            '5' => [5],
            '6' => [6],
            '7' => [7],
            '8' => [8],
            '9' => [9],
            '10' => [10],
            'J' => [10],
            'Q' => [10],
            'K' => [10]
          }

  attr_reader :cards

  def initialize
    @cards = []
    FACES.each do |key, val|
      SUITS.each do |suit|
        @cards.push([key, suit, val])
      end
    end
  end

  def deal_card
    random_card_index = (0...cards.length).to_a.sample
    cards[random_card_index]
  end
end

class Game
  include Promptable

  attr_reader :deck, :gambler, :dealer

  def initialize
    @deck = Deck.new
    @gambler = Gambler.new(@deck)
    @dealer = Dealer.new(@deck)
  end

  def start
    deal_cards
    show_initial_cards

    gambler.take_turn
    if gambler.busted?
      prompt "Gambler busted!"
      prompt "The dealer won!"
    end

    dealer.take_turn
    if dealer.busted?
      prompt "Dealer busted!"
      prompt "The gambler won!"
    end

    unless gambler.busted? || dealer.busted? then show_result end
  end

  def deal_cards
    2.times do
      gambler.hit
      dealer.hit
    end
  end

  def show_initial_cards
    prompt "You were dealt #{gambler.format_hand}"
    prompt "The dealer shows a #{dealer.reveal_card}"
  end

  def show_result
    prompt "#{determine_winner} is the winner!"
  end

  def determine_winner
    if gambler.total > dealer.total
      return "Gambler"
    else
      return "Dealer"
    end
  end
end

game = Game.new
game.start
