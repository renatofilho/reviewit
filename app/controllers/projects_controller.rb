class ProjectsController < ApplicationController
  def show
    @project = current_user.projects.find(params[:id])
  end

  def new
    @project = Project.new
    @project.users << current_user
  end

  def create
    @project = Project.new(project_params)
    set_project_users
    if @project.save
      flash[:success] = 'The project was successfully created.'

      redirect_to @project
    else
      flash.now[:danger] = 'Please, review the form fields below before try again.'

      render 'new'
    end
  end

  def edit
    if !project.owner?(current_user)
      flash[:danger] = 'Trying to edit a project with an user that is not in the owner list.'
      render :show
    end
    project
  end

  def update
    return unless project.owner?(current_user)

    params[:project].delete(:jira_password) if (params[:project] || {})[:jira_password].blank?
    project.update_attributes(project_params)
    set_project_users
    if @project.save
      flash[:success] = 'The project was successfully updated.'

      redirect_to @project
    else
      flash.now[:danger] = 'Please, review the form fields below before try again.'

      render :edit
    end
  end

  def destroy
    project.destroy
    flash[:success] = 'The project was successfully destroyed.'

    redirect_to action: :index
  end

  private

  def set_project_users
    names = params[:project][:members].is_a?(Array) ? params[:project][:members] : []
    members = User.where(name: names).to_a
    members.uniq!

    names = params[:project][:owners].is_a?(Array) ? params[:project][:owners] : []
    owners = User.where(name: names).to_a
    owners.uniq!

    # add current user as owner if it is empty to keep the project editable by someone
    owners << current_user if owners.empty?

    @project.update_users!(owners, members)
  end

  def project_params
    params.require(:project).permit(:name, :repository, :description, :linter,
                                    :gitlab_ci_project_url,
                                    :jira_username, :jira_password, :jira_ticket_regexp,
                                    :jira_api_url)
  end
end
