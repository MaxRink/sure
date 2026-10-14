class Settings::FamiliesController < ApplicationController
  layout "settings"

  def index
    @families = Current.user.families.order(:name, :id)
  end

  def update
    family = Current.user.families.find(params[:id])
    Current.select_family!(family)
    redirect_back fallback_location: root_path, notice: "Active family changed"
  end

end
