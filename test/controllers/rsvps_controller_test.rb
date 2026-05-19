require "test_helper"

class RsvpsControllerTest < ActionDispatch::IntegrationTest
  test "confirm with a valid token stamps click_confirmed_at" do
    rsvp = Rsvp.create!(email: "fan@example.com")

    get confirm_rsvp_url(token: rsvp.confirmation_token)

    assert_redirected_to root_path
    assert_not_nil rsvp.reload.click_confirmed_at
  end

  test "confirm with an unknown token is a no-op redirect" do
    get confirm_rsvp_url(token: "not-a-real-token")

    assert_redirected_to root_path
  end

  test "confirm is idempotent" do
    rsvp = Rsvp.create!(email: "again@example.com")
    get confirm_rsvp_url(token: rsvp.confirmation_token)
    first = rsvp.reload.click_confirmed_at

    travel 1.minute do
      get confirm_rsvp_url(token: rsvp.confirmation_token)
    end

    assert_equal first, rsvp.reload.click_confirmed_at
  end
end
