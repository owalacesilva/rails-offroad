class Current < ActiveSupport::CurrentAttributes
  attribute :session

  delegate :advertiser, to: :session, allow_nil: true
end
