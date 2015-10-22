class Thing::Policy
  include Gemgem::Policy

  def create?
    true
  end

  # the problem here is that we need deciders to differentiate between contexts (e.g. signed_in?)
  # that we actually already know, e.g. Create::SignedIn knows it is signed in.
  #
  # Idea: Thing::Policy::Update.()
  def update?
    edit?
  end

  def show?
    true # FIXME: make that "configurable"
  end

  def edit?
    return false unless signed_in?
    return true if admin?
    model.users.include?(user)
  end

  def delete?
    edit?
  end

  def true?
    true
  end
end
