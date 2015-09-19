class ThingsController  < ApplicationController
  respond_to :html

  def new
    form Thing::Create
    @form.prepopulate!

    render_form
  end

  def create
    return respond Thing::Create
    run Thing::Create do |op|
      return redirect_to op.model
    end

    @form.prepopulate!
    render_form
  end

  def show
    respond Thing::Show
    return

    present Thing::Show
    @op = @operation # FIXME.


    form Comment::Create # overrides @model and @form!
    @form.prepopulate!
  end

  def create_comment
    present Thing::Show
    @op = @operation # FIXME.

    run Comment::Create do |op| # overrides @model and @form!
      flash[:notice] = "Created comment for \"#{op.thing.name}\""
      return redirect_to thing_path(op.thing)
    end

    render :show
  end

  def edit
    puts "edit: @@@@??@ #{params.inspect}"

    form Thing::Update

    @form.prepopulate!

    render_form
  end

  def update
    run Thing::Update do |op|
      return redirect_to op.model
    end

    # @form.prepopulate!
    render_form
  end

  # TODO: test me.
  def destroy
    run Thing::Delete do |op|
      flash[:notice] = "#{op.model.name} deleted."
      return redirect_to root_path
    end
  end


  protect_from_forgery except: :next_comments # FIXME: this is only required in the test, things_controller_test.
  def next_comments
    present Thing::Show

    render js: concept("comment/cell/grid", @thing, page: params[:page]).(:append)
  end

private
  def render_form
    # raise @operation.class.inspect
    render text: concept("thing/cell/form", @operation),
      layout: true
  end
end