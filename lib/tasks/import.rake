require 'csv'

namespace :import do
  task :orders => :environment do
    connection = ActiveRecord::Base.connection

    orders = File.read(Rails.root.join('db/orders.csv'))
    csv = CSV.parse(orders)
    csv.each do |row_obj|
      row = row_obj.to_a
      puts row[3]
      values = [row[0], row[1], row[2], DateTime.parse(row[3]), DateTime.parse(row[4])]
      sql_values = values.collect { |r| "'#{r}'" }.join(',')
      connection.execute("INSERT INTO orders (id, order_num, user_id, created_at, updated_at) VALUES (#{sql_values})")
    end
  end

  task :users => :environment do
    connection = ActiveRecord::Base.connection

    orders = File.read(Rails.root.join('db/users.csv'))
    csv = CSV.parse(orders)
    csv.each do |row|
      values = row.to_a.collect { |r| "'#{r}'" }.join(',')
      connection.execute("INSERT INTO users (id, created_at, updated_at) VALUES (#{values})")
    end
  end
end