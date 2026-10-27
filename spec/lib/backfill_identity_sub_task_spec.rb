# frozen_string_literal: true

require "spec_helper"

describe "keycloak:backfill_identity_sub" do
  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?("keycloak:backfill_identity_sub")
  end

  after do
    Rake::Task["keycloak:backfill_identity_sub"].reenable
  end

  it "reports that identities without a subject are filled on their next login" do
    identity = create(:identity, provider: "keycloakopenid", keycloak_sub: nil)

    expect { Rake::Task["keycloak:backfill_identity_sub"].invoke }
      .to output(/1 Keycloak identities still lack a keycloak_sub.*no Keycloak Admin API client.*next Keycloak login/m).to_stdout

    expect(identity.reload.keycloak_sub).to be_nil
  end

  it "reports when every Keycloak identity already has a subject" do
    create(:identity, provider: "keycloakopenid", keycloak_sub: "keycloak-sub")
    create(:identity, provider: "other-provider", keycloak_sub: nil)

    expect { Rake::Task["keycloak:backfill_identity_sub"].invoke }
      .to output("All Keycloak identities already have a keycloak_sub.\n").to_stdout
  end
end
