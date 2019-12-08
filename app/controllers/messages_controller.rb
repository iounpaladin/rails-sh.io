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
  end
end

def play_lib (message, game, ctrl)
  ActionCable.server.broadcast 'messages',
                               message: "A liberal policy has been enacted (#{game[:faspolicies] + 1}/5).",
                               user: message.user.username,
                               elo: message.user.elo,
                               custom: 'libenact'
  ctrl.head :ok
  game[:libpolicies] += 1

  if game[:libpolicies] == 5
    game.ended = true
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
      teammaterole = role == 'Fascist' ? 'Hitler': 'Fascist'
      teammate = game[roles.index teammaterole]
      ActionCable.server.broadcast 'messages',
                                   message: "Your teammate is #{teammate} (#{teammaterole}).",
                                   user: p,
                                   elo: 0,
                                   custom: p
    end
  end
end

class MessagesController < ApplicationController

  def create
    message = Message.new(message_params)
    message.user = current_user
    ignore = false

    game = message.chatroom
    puts game.to_json

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

    if %w{pick1 pick2 pick3 pick4 pick5 pick6 pick7 pick8 pick9 pick10 ja nein}.include? message.content
      ignore = true

      if %w{ja nein}.include? message.content
        ActionCable.server.broadcast 'messages',
                                     message: "#{current_user.username} has voted!",
                                     user: message.user.username,
                                     elo: message.user.elo,
                                     custom: 'vote'
        head :ok
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

    game.save
  end

  private

  def message_params
    params.require(:message).permit(:content, :chatroom_id)
  end
end
