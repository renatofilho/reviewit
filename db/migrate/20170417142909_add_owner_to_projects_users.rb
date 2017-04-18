class AddOwnerToProjectsUsers < ActiveRecord::Migration
  def change
    add_column :projects_users, :owner, :boolean, :default => true
  end
end
