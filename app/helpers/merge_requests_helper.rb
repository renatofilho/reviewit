module MergeRequestsHelper
  def patches
    @patches ||= @mr.patches
  end

  def patch_name(patch)
    i = @mr.patches.index(patch) + 1
    patch.description.blank? ? "#{i.ordinalize} version" : patch.description
  end

  def patch_linter_status(patch)
    content_tag(:span, '', class: "fa #{patch.linter_ok? ? 'fa-check ok' : 'fa-remove fail'}")
  end

  def search_request?
    !params[:author].blank? || !params[:target_branch].blank? || !params[:subject].blank?
  end

  def merge_request_status_line(mr)
    if mr.closed?
      "Closed #{distance_of_time_in_words(Time.now, mr.updated_at)} ago,"
    else
      last_patch = mr.patch
      return if last_patch.nil?
      time = last_patch.updated_at
      last_comment = last_patch.comments.order('id DESC').limit(1).first
      time = last_comment.created_at if last_comment
      time = distance_of_time_in_words(Time.now, time)
      "Pending for #{time},"
    end
  end

  def patch_ci_status(patch)
    if patch.success?
      'review-list--success'
    elsif patch.canceled?
      'review-list--canceled'
    elsif patch.failed?
      'review-list--failure'
    end
  end

  def patch_ci_icon(patch)
    return unless patch.project.gitlab_ci?

    tag = patch.unknown? ? :i : :a
    content_tag(tag, '', class: "tipped fa #{patch_ci_fa(patch)}",
                         'data-tip' => patch_ci_tip(patch),
                         target: "patch-#{patch.gitlab_ci_hash}",
                         href: "#{patch.project.gitlab_ci_project_url}/builds/#{patch.gitlab_ci_build}")
  end

  def should_show_patch_comment_divisor(patch, main_patch)
    return patch.comments.general.any? if patch == main_patch
    patch.comments.any?
  end

  def diff_snippet(patch, location)
    patch.code_at((location - 2)..location).map do |line|
      content_tag(:div, line, class: "#{code_line_type(line)} snippet")
    end.join.html_safe
  end

  def diff_file_status_class(file)
    flags = []
    if file.new?
      flags.push 'new'
      flags.push 'chmod-changed'
    elsif file.deleted?
      flags.push 'deleted'
    elsif file.renamed?
      flags.push 'renamed'
    elsif file.chmod_changed?
      flags.push 'chmod-changed'
    end
    flags.join(' ')
  end

  def diff_file_status(file)
    flags = {}
    if file.new?
      flags['new'] = 'new'
      flags['chmod-changed'] = "chmod #{file.new_chmod}"
    elsif file.deleted?
      flags['deleted'] = 'deleted'
    elsif file.renamed?
      flags['renamed'] = "renamed #{file.similarity}"
    elsif file.chmod_changed?
      flags['chmod-changed'] = "chmod change: #{file.old_chmod} → #{file.new_chmod}"
    end

    # interdiff tags
    flags['interdiff-tag'] = file.interdiff_tag if file.interdiff_tag

    flags.map do |flag, label|
      content_tag(:span, label, class: "flag #{flag}")
    end.join.html_safe
  end

  private

  def code_line_type(line)
    case line[0]
    when '+' then 'add'
    when '-' then 'del'
    when '@' then 'info'
    end
  end

  def parse_addons_template(template, patch)
    template.gsub!('#{mr_id}', patch.merge_request.id.to_s)
    template.gsub!('#{mr_version}', patch.version.to_s)
  end

  def patch_ci_tip(patch)
    "CI #{patch.gitlab_ci_status}"
  end

  def patch_ci_fa(patch)
    case patch.gitlab_ci_status
    when 'failed' then 'fa-remove fail'
    when 'success' then 'fa-check ok'
    when 'unknown' then 'fa-question'
    when 'pending' then 'fa-clock-o'
    when 'canceled' then 'fa-ban'
    when 'running' then 'fa-cog fa-spin'
    end
  end

  def target_branch_options
    options = MergeRequest.uniq.where(project_id: @project.id).order('target_branch ASC').pluck(:target_branch)
    options.unshift(['', ''])
    options_for_select(options, params[:target_branch])
  end

  def author_options
    options = User.uniq.order('name ASC').joins(:merge_requests)
                  .where('merge_requests.project_id = ?', @project.id).pluck(:name, :id)
    options.unshift(['', ''])
    options_for_select(options, params[:author])
  end
end
