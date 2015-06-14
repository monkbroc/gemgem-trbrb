# TODO: policy: users can only delete authors when they added them? Delete things. (chapt 9)

# EXPLAIN validation/table lock etc. later
# split up files (update goes to separate.) split up contract?
# form: presentation logic for form. (use cell?)
# talk about this? http://stackoverflow.com/questions/4116415/preselect-check-box-with-rails-simple-form

# how does skipping work: Form.new[user, user2], then validate with [user, user2:skip,user], user2 will still be there but not updated.
#   save => users = [user] (without deleted), removes user from collection.
class Thing < ActiveRecord::Base
  class Create < Trailblazer::Operation
    include CRUD#, Dispatch
    model Thing, :create

    contract do
      feature Disposable::Twin::Persisted

      property :name
      property :description

      validates :name, presence: true
      validates :description, length: {in: 4..160}, allow_blank: true

      collection :users,
          prepopulator:      :prepopulate_users!,
          populate_if_empty: :populate_users!,
          skip_if:           :all_blank do

        property :email
        validates :email, presence: true, email: true
        validate :authorship_limit_reached?

        def readonly? # per form.
          model.persisted?
        end
        alias_method :removeable?, :readonly?

        def remove
        end

      private
        def authorship_limit_reached?
          return if model.authorships.find_all { |au| au.confirmed == 0 }.size < 5
          errors.add("user", "This user has too many unconfirmed authorships.")
        end
      end
      validates :users, length: {maximum: 3}

    private
      def prepopulate_users!(options)
        (3 - users.size).times { users << User.new }
      end

      def populate_users!(params, options)
        User.find_by_email(params["email"]) or User.new
      end
    end

    def process(params)
      validate(params[:thing]) do |f|
        f.save
        # dispatch :notify_authors!

        # hook << this
        # hook << that
        #   where hook is callable.
        # dispatch....on_add(hook)
        # or:
        # f.users.on_add(hook)

        Disposable::Twin::Callback::Dispatch.new(f.users).on_add { |twin| on_add!(twin) }

        # dispatch :notify_authors!
        dispatch :notify_author! { f.users.on_add { |twin| on_add!(twin) } }
        dispatch :notify_authors!
        # nested configuration in "callback" class
        # on_create :mails
        #
        # collection :users do
        #   on_add :notify_authors
        #   on_add :recalculate_size
        # end
        #
        # run: callbacks.([:on_add, ..])
        #   allows removing, changing in inherited code.

        reset_authorships!
      end
    end

    def notify_authors!
      f.users.on_add { |twin| on_add!(twin) }
    end

  private
    def on_add!(twin)
      # only one mail: welcome and here's your project, or just "here's another project, dude"

      # reset_authorships!
      # raise twin.inspect
      puts "``````````@@@@@dded: #{twin.inspect}"
    end
    def on_remove!(twin)
      puts "``````````@@@@@remove: #{twin.inspect}"
    end
    # def notify_authors!
    #   # TODO: mark new authors and send mails only to those.
    #   model.users.collect { |user| NewUserMailer.welcome_email(user) }
    # end

    def reset_authorships!
      model.authorships.each { |authorship| authorship.update_attribute(:confirmed, 0) }
    end
  end

  class Update < Create
    action :update
    # skip_dispatch :notify_authors!

    contract do
      property :name, writeable: false

      # DISCUSS: should inherit: true be default?
      collection :users, inherit: true, skip_if: :skip_user? do
        property :email, skip_if: :skip_email?

        def skip_email?(fragment, options)
          model.persisted?
        end
      end



      # Disposable::Twin::Callback::Runner.new(f.users).on_delete { |twin| on_remove!(twin) }

    private
      def skip_user?(fragment, options)
        # don't process if it's getting removed!
        return true if fragment["remove"] == "1" and users.delete(users.find { |u| u.id.to_s == fragment["id"] })

        # skip when user is an existing one.
        # return true if users[index] and users[index].model.persisted?

        # replicate skip_if: :all_blank logic.
        return true if fragment["email"].blank?
      end
    end
  end
end