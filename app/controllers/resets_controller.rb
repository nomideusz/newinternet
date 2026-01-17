class ResetsController < ApplicationController
  allow_unauthenticated_access

  def create
    if params[:confirm] == "yes"
      ActiveRecord::Base.transaction do
        User.destroy_all
        Account.destroy_all
      end
      render plain: "DATABASE RESET. Go to /"
    else
      render plain: "To reset DB, add ?confirm=yes to URL"
    end
  end
end
