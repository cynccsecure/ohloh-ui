class Account < ActiveRecord::Base
  DEFAULT_LEVEL = 0
  ADMIN_LEVEL   = 10
  DISABLE_LEVEL = -10
  SPAMMER_LEVEL = -20

  oh_delegators :stack_extension, :organization_extension, :project_extension

  has_many :api_keys
  has_many :actions
  belongs_to :organization

  def admin?
    level == ADMIN_LEVEL
  end

  def disabled?
    level < DEFAULT_LEVEL
  end

  def activated?
    activated_at != nil
  end

  def default_stack
    stacks << Stack.new unless @cached_default_stack || stacks.count > 0
    @cached_default_stack ||= stacks[0]
  end
end
