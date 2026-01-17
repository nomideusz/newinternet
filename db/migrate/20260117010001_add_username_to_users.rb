class AddUsernameToUsers < ActiveRecord::Migration[8.2]
  def change
    # Add username column (required for login)
    add_column :users, :username, :string
    add_index :users, :username, unique: true

    # Make email_address nullable (no longer required for auth)
    change_column_null :users, :email_address, true

    # Remove unique constraint on email (keeping column for profile)
    remove_index :users, :email_address
    add_index :users, :email_address
  end
end
