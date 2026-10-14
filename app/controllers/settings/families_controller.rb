class Settings::FamiliesController < ApplicationController
  layout "settings"

  before_action :require_super_admin!, only: [ :new, :create ]

  def index
    @families = Current.user.families.order(:name, :id)
  end

  def new
    @family = Family.new(moniker: "Group")
  end

  def create
    @family = Family.new(family_params)

    Family.transaction do
      @family.save!
      Current.user.family_memberships.create!(family: @family, role: "admin")
    end

    Current.select_family!(@family)
    redirect_to settings_families_path, notice: "Family space created"
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def update
    family = Current.user.families.find(params[:id])
    Current.select_family!(family)
    redirect_back fallback_location: root_path, notice: "Active family changed"
  end

  private

    def require_super_admin!
      return if Current.user&.super_admin?

      redirect_to settings_families_path, alert: "Only instance administrators can create family spaces"
    end

    def family_params
      params.require(:family).permit(:name, :moniker)
    end

end
