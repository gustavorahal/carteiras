class AddUserToInvestidor < ActiveRecord::Migration[6.1]
  def change
    add_reference :investidores, :user, foreign_key: true
  end
end
