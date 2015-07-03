require 'test_helper'

require "minitest/rails/capybara"
class IntegrationTest < Capybara::Rails::TestCase
  def sign_in!(*)
    sign_up! #=> Session::SignUp

    visit "/sessions/sign_in_form"

    submit!(email="fred@trb.org", password="123456")
  end

  def sign_up!(email="fred@trb.org", password="123456")
    Session::SignUp::Admin.(user: {email: email, password: password})
  end

  def submit!(email, password)
    within("//form[@id='new_session']") do
      fill_in 'Email',    with: email
      fill_in 'Password', with: password
    end
    click_button "Sign in!"
  end
end

class SessionsControllerTest < IntegrationTest
  it do
    visit "sessions/sign_up_form"

    page.must_have_css "#user_email"
    page.must_have_css "#user_password"
    page.must_have_css "#user_confirm_password"

    # empty
    submit_sign_up!("", "", "")

    page.must_have_css "#user_email"

    # wrong everything.
    submit_sign_up!("wrong", "123", "")
    page.must_have_css "#user_email" # value?

    # password mismatch.
    submit_sign_up!("Scharrels@trb.org", "123", "321")
    page.must_have_css "#user_email" # value?

    submit_sign_up!("Scharrels@trb.org", "123", "123")
    page.must_have_css "#session_email"
    page.must_have_css "#session_password"

  end

  # wrong login.
  it do
    visit "/sessions/sign_in_form"
    # login form is present.
    page.must_have_css "#session_email"
    page.must_have_css "#session_password"

    submit! "vladimir@horowitz.ru", "forgot"

    # login form is present, again.
    page.must_have_css "#session_email"
    page.must_have_css "#session_password"

    # empty login.
    submit! "", ""

    # login form is present, again.
    page.must_have_css "#session_email"
    page.must_have_css "#session_password"
  end

  # sucessful session.
  it do
    visit "sessions/sign_up_form"
    submit_sign_up!("fred@trb.org", "123", "123")
    submit!("fred@trb.org", "123")

    page.must_have_content "Hi, fred@trb.org" # login success.

    # no sign_in screen for logged in.
    visit "/sessions/sign_in_form"
    page.must_have_content "Welcome to Gemgem!"

    # no sign_up screen for logged in.
    visit "/sessions/sign_up_form"
    page.must_have_content "Welcome to Gemgem!"
  end


  def submit_sign_up!(email, password, confirm)
    within("//form[@id='new_user']") do
      fill_in 'Email',    with: email
      fill_in 'Password', with: password
      fill_in 'Password, again', with: confirm
    end
    click_button "Sign up!"
  end
end