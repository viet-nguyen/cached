class ArticlesController < ApplicationController
  before_filter :authenticated?, except: [:index, :search, :show] # allow anonymous browsing of articles; currently, the only route enabled is '/demo'
  before_filter :inject_current_user_into_params, only: [:create, :update] # enforce correct current user, an alternative could be using mass assignment
  before_filter :filter_incoming_title_and_body_params, only: [:create, :update] # convert title to titlecase, strip style attributes from body
  respond_to :json, except: :index
  
   # on error, return error message with 400, client should show error message
   # on success, return new article in json format, client should extract article id
  def create
    article = Article.create params['article']
    if article.invalid?
      render status: 400, inline: extract_first_error_message(article.errors.messages)
    else
      respond_with article
    end
  end
  
  def destroy
    article = Article.of(current_user).find params[:id]
    article.destroy
    respond_with article
  end
  
  # load all articles' titles into Backbone on start up
  def index
    user = params[:demo] ? 2 : current_user # user must be demo user or authorized current user
    if user
      @articles = Article.of(user).for_index.chronological
    else 
      redirect_to login_path and return
    end
  end
  
  def search
    user = current_user || 2 # if user is not authorized current user, default to demo user
    query = params[:q].try(:downcase)
    if query.blank?
      respond_with Article.of(user).for_index.chronological
    else
      respond_with Article.of(user).for_index.chronological.where('LOWER(title) like ?', "%#{query}%")
    end
  end
  
  def show
    respond_with Article.find params[:id]
  end
  
  # on error, return error message with 400, client should show error message
  # on success, return nothing with 204, client should redirect to :show
  def update
    article = Article.of(current_user).find params[:id] rescue render status: 500, inline: 'Article not found' and return
    # old_article = article.clone TODO used to update Redis index
    article.update_attributes params['article']
    if article.invalid?
      render status: 400, inline: extract_first_error_message(article.errors.messages)
    else
      render status: 204, nothing: true
    end
  end
  
  private
  
  def authenticated?
    if !current_user
      redirect_to login_path and return
    end
  end

  def inject_current_user_into_params
    params['article']['user'] = current_user
  end
  
  def filter_incoming_title_and_body_params
    params['article']['title'] = params['article']['title'].split(' ').map do |word|
      if word[1..-1] =~ /[^a-z']/
        word
      else
        word.capitalize
      end
    end.join(' ')
    
    blah = /[0-9a-zA-Z\-\(\)\/_.,:;!%' ]+/
    params['article']['body'].gsub! /\sstyle="#{blah}"/, ''
    params['article']['body'].gsub! /\sclass="#{blah}"/, ''
    params['article']['body'].gsub! /\sheight="#{blah}"/, ''
    params['article']['body'].gsub! /\swidth="#{blah}"/, ''
    params['article']['body'].gsub! /\starget="#{blah}"/, ''
    params['article']['body'].gsub! /\sdata-[a-z-]+="#{blah}"/, ''
  end

end