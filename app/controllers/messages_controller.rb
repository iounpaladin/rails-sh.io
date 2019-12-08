def endgame(message, game, ctrl)
  game.players.each_with_index { |x, i| ActionCable.server.broadcast 'messages',
                                                                     message: "#{x} was #{game.roles[i]}.",
                                                                     user: message.user.username,
                                                                     elo: 0,
                                                                     custom: 'announcement' }
  ctrl.head :ok
end

def play_fas (message, game, ctrl)
  ActionCable.server.broadcast 'messages',
                               message: "A fascist policy has been enacted (#{game[:faspolicies] + 1}/6).",
                               user: message.user.username,
                               elo: message.user.elo,
                               custom: 'fasenact'
  ctrl.head :ok
  game[:faspolicies] += 1

  if game[:faspolicies] == 6
    game.ended = true
    ActionCable.server.broadcast 'messages',
                                 message: "The 6th fascist policy has been enacted. Fascists win the game.",
                                 user: message.user.username,
                                 elo: 0,
                                 custom: 'announcement'

    endgame message, game, ctrl
  end

  if game.fasboard[game.faspolicies - 1] == 'peek'
    ActionCable.server.broadcast 'messages',
                                 message: "You peek at #{game.deck.first(3).join ''}.",
                                 user: message.user.username,
                                 elo: 0,
                                 custom: game.players[game.president - 1]
  end
end

def play_lib (message, game, ctrl)
  ActionCable.server.broadcast 'messages',
                               message: "A liberal policy has been enacted (#{game[:libpolicies] + 1}/5).",
                               user: message.user.username,
                               elo: message.user.elo,
                               custom: 'libenact'
  ctrl.head :ok
  game[:libpolicies] += 1

  if game[:libpolicies] == 5
    game.ended = true
    ActionCable.server.broadcast 'messages',
                                 message: "The 5th liberal policy has been enacted. Liberals win the game.",
                                 user: message.user.username,
                                 elo: 0,
                                 custom: 'announcement'

    endgame message, game, ctrl
  end
end

def start_game(game, ctrl)
  game[:started] = true
  game.save

  game.players.each do |p|
    role = game.roles[game.players.index p]
    ActionCable.server.broadcast 'messages',
                                 message: "Your secret role is #{role}.",
                                 user: p,
                                 elo: 0,
                                 custom: p

    if %w{Fascist Hitler}.include? role
      teammaterole = role == 'Fascist' ? 'Hitler' : 'Fascist'
      teammate = game.players[game.roles.index teammaterole]
      ActionCable.server.broadcast 'messages',
                                   message: "Your teammate is #{teammate} (#{teammaterole}).",
                                   user: p,
                                   elo: 0,
                                   custom: p
      ctrl.head :ok
    end
  end

  game.president = 1

  ActionCable.server.broadcast 'messages',
                               message: "#{game.players[game.president - 1]} is the president. They must pick a chancellor.",
                               user: p,
                               elo: 0,
                               custom: 'announcement'
end

class MessagesController < ApplicationController

  def create
    message = Message.new(message_params)
    message.user = current_user
    ignore = false

    game = message.chatroom
    puts game.to_json
    puts "CTRL-F FOR ME" unless game.draw.all? { |x| %w{R B}.include? x }
    puts "CTRL-F FOR ME" unless game.discard.all? { |x| %w{R B}.include? x }

    if game.ended
      ActionCable.server.broadcast 'messages',
                                   message: message.content,
                                   user: message.user.username,
                                   elo: message.user.elo,
                                   custom: ''
      head :ok
      return
    end

    if message.content == 'sit'
      ignore = true

      unless game[:started] || (game[:players].include? current_user.username)
        game[:players].append current_user.username

        ActionCable.server.broadcast 'messages',
                                     message: "#{current_user.username} has sat down (#{game[:players].length}/5).",
                                     user: message.user.username,
                                     elo: message.user.elo,
                                     custom: 'sit'

        if game[:players].length == 5
          start_game game, self
        end
      end

      game.save
    end

    unless game.started
      return
    end

    # # TEST
    # if message.content == 'f'
    #   play_fas message, game, self
    # end
    #
    # # TEST
    # if message.content == 'l'
    #   play_lib message, game, self
    # end

    if %w{pick1 pick2 pick3 pick4 pick5 ja nein cut1 cut2 cut3}.include? message.content
      ignore = true

      if %w{ja nein}.include? message.content
        return unless game.needsvotes
        game.votes[game.players.index message.user.username] = message.content

        ActionCable.server.broadcast 'messages',
                                     message: "#{current_user.username} has voted!",
                                     user: message.user.username,
                                     elo: message.user.elo,
                                     custom: 'vote'

        head :ok

        if game.votes.all? { |x| %w{ja nein}.include? x }
          # votes are in
          jas = 0
          game.votes.each_with_index do |x, i|
            ActionCable.server.broadcast 'messages',
                                         message: "#{game.players[i]} has voted #{x}.",
                                         user: message.user.username,
                                         elo: message.user.elo,
                                         custom: 'vote'

            head :ok
            jas += (x == "ja" ? 1 : 0)
          end

          if jas >= 3
            # gov passes
            if game.roles[game.chancellor - 1] == 'Hitler' && game.faspolicies >= 3
              game.ended = true
              game.save
              ActionCable.server.broadcast 'messages',
                                           message: "Hitler has been elected chancellor after 3 fascist policies have been enacted. Fascists win.",
                                           user: message.user.username,
                                           elo: 0,
                                           custom: 'announcement'

              endgame message, game, self
              return
            end

            game.draw = game.deck.shift 3
            ActionCable.server.broadcast 'messages',
                                         message: "You have drawn #{game.draw.join ''}. Type 'cut1', 'cut2', or 'cut3' to pick which policy to DISCARD.",
                                         user: message.user.username,
                                         elo: message.user.elo,
                                         custom: game.players[game.president - 1]
          else
            # gov fails
            game.tracker += 1
            game.president += 1
            game.president = 1 if game.president > 5

            if game.tracker >= 3
              game.tracker = 0

              policy = game.deck.shift 1
              if policy == 'R'
                play_fas message, game, self
              else
                play_lib message, game, self
              end

              if game.ended
                return
              end

              ActionCable.server.broadcast 'messages',
                                           message: "#{game.players[game.president - 1]} is the president. They must pick a chancellor.",
                                           user: game.players[game.president - 1],
                                           elo: 0,
                                           custom: 'announcement'
            end

            game.votes = Array.new(5) { '' }
            game.needsvotes = true

            game.president += 1
            if game.president > 5
              game.president = 1
            end

            ActionCable.server.broadcast 'messages',
                                         message: game.tracker,
                                         user: message.user.username,
                                         elo: message.user.elo,
                                         custom: 'tracker'
          end
        end

        if game.deck.length < 3
          game.deck = game.discard.clone + game.deck.clone
          game.discard = []
          game.deck.shuffle!
        end

        game.save if game.changed?
      elsif message.content.include? "pick"
        # pick
        # p message
        return unless game.players[game.president - 1] == message.user.username
        # p 'a'
        pick = (message.content.sub /[a-z]+/, '').to_i
        return if pick == game.president
        # p pick

        game.prescut = -1
        game.chanccut = -1

        game.chancellor = pick

        ActionCable.server.broadcast 'messages',
                                     message: "#{game.players[game.chancellor - 1]} has been appointed chancellor. Please vote. (Government is #{game.president}#{game.chancellor}).",
                                     user: p,
                                     elo: 0,
                                     custom: 'announcement'

        game.needsvotes = true
        game.save
      else
        p message
        if message.user.username == game.players[game.president - 1] && game.prescut == -1
          # pres cut
          pcut = (message.content.sub /[a-z]+/, '').to_i - 1
          game.prescut = pcut
          game.discard << game.draw[pcut]
          game.draw.delete_at pcut
          puts "sending to chanc"
          p game.draw
          ActionCable.server.broadcast 'messages',
                                       message: "You have recieved #{game.draw.join ''}. Type 'cut1' or 'cut2' to pick which policy to DISCARD.",
                                       user: message.user.username,
                                       elo: message.user.elo,
                                       custom: game.players[game.chancellor - 1]
        elsif message.user.username == game.players[game.chancellor - 1] && game.prescut != -1 && game.chanccut == -1
          ccut = (message.content.sub /[a-z]+/, '').to_i - 1
          game.chanccut = ccut
          game.discard << game.draw[ccut]
          game.draw.delete_at ccut
          policy = game.draw[0]

          play_fas message, game, self if policy == 'R'
          play_lib message, game, self if policy == 'B'

          if game.ended
            return
          end

          game.votes = Array.new(5) { '' }

          game.president += 1
          if game.president > 5
            game.president = 1
          end

          ActionCable.server.broadcast 'messages',
                                       message: "#{game.players[game.president - 1]} is the president. They must pick a chancellor.",
                                       user: game.players[game.president - 1],
                                       elo: 0,
                                       custom: 'announcement'

          # TODO: VETO
        end
      end
    end

    unless ignore
      if message.save
        ActionCable.server.broadcast 'messages',
                                     message: message.content,
                                     user: message.user.username,
                                     elo: message.user.elo,
                                     custom: ''
        head :ok
      end
    end

    game.save if game.changed?
  end

  private

  def message_params
    params.require(:message).permit(:content, :chatroom_id)
  end
end
