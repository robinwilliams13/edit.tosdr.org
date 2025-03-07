class SpamController < ApplicationController
  include Pundit
  include ApplicationHelper

  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def flag_as_spam
    authorize Spam
    
    flagger_is_permitted = current_user && (current_user.admin? || current_user.curator?) ? true : false


    spam_owner = User.find(params[:spammable_type].constantize.find(params[:spammable_id]).user_id)
  
    if spam_owner.admin or spam_owner.curator or spam_owner.bot
      flash[:alert] = "You are not authorized to perform this action on admins, curators or bots."
      redirect_to(request.referrer || root_path)
      return
    end

    spam = Spam.new(spammable_type: params[:spammable_type], spammable_id: params[:spammable_id].to_i, flagged_by_admin_or_curator: flagger_is_permitted)
    spam.save


    puts "Flagged as Spam"
    report_spam(spam.spammable_type.constantize.find(spam.spammable_id).summary, "spam")
    flash[:notice] = "Comment has been marked as Spam."
    redirect_to(request.referrer || root_path)
  end

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def spam_params
    params.require(:spam).permit(:spammable_type, :spammable_id)
  end
end
