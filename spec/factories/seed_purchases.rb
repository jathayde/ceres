FactoryBot.define do
  factory :seed_purchase do
    plant
    seed_source
    year_purchased { Date.current.year }
    packet_count { 1 }
    used_up { false }
  end
end
