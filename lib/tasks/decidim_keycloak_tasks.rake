# frozen_string_literal: true

namespace :keycloak do
  desc "Report Keycloak identities whose OIDC sub will be stored on their next login"
  task backfill_identity_sub: :environment do
    identities_without_sub = Decidim::Identity.where(provider: Decidim::Keycloak::IdentitySub::PROVIDER,
                                                     keycloak_sub: nil).count

    if identities_without_sub.zero?
      puts "All Keycloak identities already have a keycloak_sub."
    else
      puts "#{identities_without_sub} Keycloak identities still lack a keycloak_sub."
      puts "This gem has no Keycloak Admin API client, so it cannot safely resolve existing subjects."
      puts "Their keycloak_sub will be stored from the verified OIDC callback on their next Keycloak login."
    end
  end
end
