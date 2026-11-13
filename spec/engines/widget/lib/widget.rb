# frozen_string_literal: true

# An engine that ships a module in its assets, the way gems like astrology-rails
# do. It lives outside the dummy app, as an installed gem would.
module Widget
  class Engine < Rails::Engine
  end
end
