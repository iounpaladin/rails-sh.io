json.extract! game, :id, :title, :libswon, :winmethod, :playercount, :players, :turns, :created_at, :updated_at
json.url game_url(game, format: :json)
