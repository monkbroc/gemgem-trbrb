require "test_helper"

# Put in a seperate file
module PolicyTestHelper
  def permissions(*list, &block)
    @current_permissions = list
    describe list.join(", ") { instance_eval(&block) }
  end

  def current_permissions
    @current_permissions || []
  end

  def it_allows_access
    it_allows_access_to nil
  end

  def it_denies_access
    it_denies_access_to nil
  end

  def it_allows_access_to(role)
    let(:user) { role }
    current_permissions.each do |permission|
      it { policy.public_send(permission).must_equal true }
    end
  end

  def it_denies_access_to(role)
    let(:user) { role }
    current_permissions.each do |permission|
      it { policy.public_send(permission).must_equal false }
    end
  end
end

class ThingPolicyTest < MiniTest::Spec
  include PolicyTestHelper

  let (:thing_author) { User::Create.(user: {email: "jd@trb.org"}).model }
  let (:thing) { Thing::Create.(thing: {name: "Bad Religion", users: [{"email" => thing_author.email}]}).model }

  let (:policy) { Thing::Policy.new(user, thing) }

  # Roles
  let (:anonymous_user) { nil }
  let (:author) { thing_author }
  let (:other_user) { User::Create.(user: {email: "someone@example.com"}).model }
  let (:admin) { User::Create.(user: {"email"=> "admin@trb.org"}).model }

  permissions :create? do
    it_allows_access
  end

  permissions :edit?, :update? do
    it_denies_access_to anonymous_user
    it_allows_access_to admin
    it_allows_access_to author
    it_denies_access_to other_user
  end

  permissions :show? do
    it_allows_access
  end
end
