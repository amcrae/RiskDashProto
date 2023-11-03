# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the user here. For example:
    #
    #   return unless user.present?
    #   can :read, :all
    #   return unless user.admin?
    #   can :manage, :all
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, published: true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/blob/develop/docs/define_check_abilities.md
    
    # unauthenticated permissions
    can :read, SystemGraph
    can :read, Segment
    can :read, SegmentConnection
    can :read, Asset
    puts "user.present? == #{user.present?}"
    return unless user.present?

    # all authenticated permissions
    can :read, MLocation
    can :read, Measurement
    can :read, RiskAssessment

    puts "user.role_name == #{user.role_name}" 
    if user.role_name == "TECHNICIAN"
      can :repair, Asset
      can :write, Asset
      can :write, Segment
      can :create, Segment
      can :create, Asset
    elsif user.role_name == "TERRORIST"
      can :sabotage, Asset
    end
    
  end
end
