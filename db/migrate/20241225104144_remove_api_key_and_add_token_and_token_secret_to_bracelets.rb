
class RemoveApiKeyAndAddTokenAndTokenSecretToBracelets < ActiveRecord::Migration[7.2]
  def change
    remove_column :bracelets, :api_key, :string, if_exists: true

    add_column :bracelets, :token, :string
    add_column :bracelets, :token_secret, :string
  end
end
