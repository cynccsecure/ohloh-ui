# frozen_string_literal: true

class Position::Hooks
  delegate :project_id, :project_id_before_last_save, :saved_change_to_project_id?,
           :name_id, :name_id_before_last_save, :saved_change_to_name_id?, :account, :account_id, to: :@position

  def after_save(position)
    @position = position

    update_account_info
    update_affected_kudos if name_id
  end

  def after_destroy(position)
    @position = position

    create_person if name_id
    cleanup_aliases
    update_account_info
    unlink_affected_kudos if name_id
  end

  def after_create(position)
    @position = position

    transfer_kudos_and_destroy_previous_unclaimed_person if name_id
  end

  def after_update(position)
    @position = position

    transfer_kudos_and_destroy_previous_unclaimed_person if name_id && name_or_project_changed?
    create_unclaimed_person_for_previous_state if name_id_before_last_save && name_or_project_changed?
  end

  private

  def cleanup_aliases
    aliases = Alias.joins(:edits)
                   .not_deleted
                   .where(preferred_name_id: name_id)
                   .where('aliases.project_id' => project_id)
                   .where('edits.type' => 'CreateEdit')
                   .where('edits.undone' => false)
                   .where('(edits.account_id = :account_id AND undone_by IS NULL)
                            OR undone_by = :account_id', account_id: account_id)
                   .distinct

    soft_delete_aliases(aliases)
  end

  def soft_delete_aliases(aliases)
    aliases.each do |alias_object|
      account = verified_manager_or_admin(alias_object)
      alias_object.find_create_edit.undo!(account)
    end
  end

  def transfer_kudos_and_destroy_previous_unclaimed_person
    unclaimed_person = Person.find_by(project_id: project_id, name_id: name_id)
    return unless unclaimed_person

    transfer_kudos_to_account_person(unclaimed_person) if account.person && unclaimed_person.kudo_score
    unclaimed_person.destroy
  end

  def verified_manager_or_admin(alias_object)
    access_verified = !account.access.disabled? && account.access.verified?
    access_verified && alias_object.project.managers.include?(account) ? account : Account.hamster
  end

  # rubocop:disable Metrics/AbcSize
  def transfer_kudos_to_account_person(unclaimed_person)
    if account.person.kudo_score
      account.person.update(kudo_score: [unclaimed_person.kudo_score, account.person.kudo_score].max,
                            kudo_rank: [unclaimed_person.kudo_rank, account.person.kudo_rank].max,
                            kudo_position: [unclaimed_person.kudo_position, account.person.kudo_position].min)
    else
      account.person.update(kudo_score: unclaimed_person.kudo_score, kudo_rank: unclaimed_person.kudo_rank,
                            kudo_position: unclaimed_person.kudo_position)
    end
  end
  # rubocop:enable Metrics/AbcSize

  def name_or_project_changed?
    saved_change_to_name_id? || saved_change_to_project_id?
  end

  def create_unclaimed_person_for_previous_state
    Person.create(project_id: project_id_before_last_save, name_id: name_id_before_last_save)
  end

  def create_person
    Person.create(project_id: project_id, name_id: name_id)
  end

  def update_account_info
    AccountAnalysisJob.schedule_account_analysis(account, 10.minutes)
    account.update_akas
  end

  def unlink_affected_kudos
    Kudo.where(project_id: project_id, name_id: name_id).find_each do |kudo|
      kudo.update(account_id: nil)
    end
  end

  def update_affected_kudos
    Kudo.where(project_id: project_id, name_id: name_id).find_each do |kudo|
      if kudo.sender == account
        # Can't kudo yourself! If you claim a contribution you've kudo'd, you lose the kudo.
        kudo.destroy
      else
        kudo.update(account_id: account_id)
      end
    end
  end
end
