# frozen_string_literal: true

require "omniauth/strategies/keycloak-openid"

module Decidim
  module Keycloak
    # This is the engine that runs on the public interface of keycloak.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Keycloak

      initializer "decidim.keycloak.middleware" do |app|
        omniauth_config = Rails.application.secrets[:omniauth]
        next if omniauth_config[:keycloakopenid].blank?

        app.config.middleware.use OmniAuth::Builder do
          provider :keycloak_openid, setup: lambda { |env|
            request = Rack::Request.new(env)
            organization = Decidim::Organization.find_by(host: request.host)
            config = organization.enabled_omniauth_providers[:keycloakopenid]
            # remove the language parameter from the callback url
            # env["omniauth.strategy"].options[:client_options][:redirect_uri] = request.url.split("?").first
            #env["omniauth.strategy"].options[:name] = "Login with Keycloak" # replace with config name
           # env["omniauth.strategy"].options[:callback_path] = request.url.split("?").first
            env["omniauth.strategy"].options[:client_id] = config[:client_id]
            env["omniauth.strategy"].options[:client_secret] = config[:client_secret]
            env["omniauth.strategy"].options[:client_options] = { site: config[:site], realm: config[:realm], base_url: config[:base_url], redirect_uri: "/users/auth/keycloakopenid/callback"}
          }
        end
      end

      config.to_prepare do
        class OmniAuth::Strategies::KeycloakOpenId
          uid { raw_info["preferred_username"] }

          info do
            {
              nickname: raw_info["preferred_username"],
              name: raw_info["name"],
              email: raw_info["email"]
            }
          end
        end
      end

      initializer "decidim_keycloak.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end
    end
  end
end
