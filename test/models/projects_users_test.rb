require 'test_helper'

class PojectsUsersTest < ActiveSupport::TestCase
  test "should add user to the owner list" do

    # create a project without owner
    project = create(:project)
    assert project.owners.empty?
    assert project.members.empty?

    owner = create(:user, name: 'Bill')
    # add owner into the user list (will be ownder because this is the default value)
    project.users << owner
    assert project.members.empty?
    assert !project.owners.empty?

    assert project.users.include?(owner)
    assert project.owners.exists?(user_id: owner.id)
  end

  test "create a project with user as owner" do
    owner = create(:user, name: 'Bill')

    project = create(:project, users: [ owner ])
    assert project.members.empty?
    assert !project.owners.empty?
    assert project.owners.exists?(user_id: owner.id)
  end

  test "create a project with members" do
    owner = create(:user, name: 'Bill')
    devel1 = create(:user, name: 'Jhon')
    devel2 = create(:user, name: 'Janne')

    project = create(:project, users: [ owner ])
    assert project.members.empty?
    project.update_users!([owner], [devel1, devel2])
    assert !project.members.empty?
    assert project.members.exists?(user_id: devel1.id)
    assert project.members.exists?(user_id: devel2.id)
  end

  test "check if user is one of the owners" do
    owner = create(:user, name: 'Bill')
    devel = create(:user, name: 'Janne')

    project = create(:project, users: [ owner ])
    assert project.owner?(owner)
    assert !project.owner?(devel)
  end

  test "add a second owner" do
    owner = create(:user, name: 'Bill')
    devel = create(:user, name: 'Janne')

    project = create(:project, users: [ owner ])
    project.update_users!([owner, devel], [])
    assert project.owner?(owner)
    assert project.owner?(devel)
  end

  test "remove member from project" do
    owner = create(:user, name: 'Bill')
    devel = create(:user, name: 'Janne')
    devel1 = create(:user, name: 'Jhon')

    project = create(:project, users: [ owner ])
    project.update_users!([owner], [devel, devel1])

    assert project.members.exists?(user_id: devel.id)
    assert project.members.exists?(user_id: devel1.id)

    project.update_users!([owner], [devel])

    assert project.members.exists?(user_id: devel.id)
    assert !project.members.exists?(user_id: devel1.id)
  end

  test "save project with empty owner should raise a error" do
    owner = create(:user, name: 'Bill')
    project = create(:project, users: [ owner ])
    assert_raises(ActiveRecord::RecordNotSaved) do
      project.update_users!([], [])
    end
    assert project.owner?(owner)
  end
end
