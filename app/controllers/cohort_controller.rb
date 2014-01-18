class CohortController < ApplicationController
  def index
    @limit = params[:limit] || 8
    raise if @limit.to_s !~ /^[0-9]+$/

    # Find cohorts, organize user counts by week
    @user_counts_by_week = []
    @weeks = []
    users_by_week_query = connection.execute(
"select 
  week(created_at) as week, 
  count(id) as users_count 
from 
  users
group by
  week(created_at)
order by
  created_at desc
limit #{@limit}")
    users_by_week_query.each do |week, users_count|
      @user_counts_by_week << [week, users_count]
      @weeks << week
    end

    # Find orders by cohort
    orders_since_signup_query = connection.execute(
"select 
  week(users.created_at), 
  orders.id as order_id, 
  users.id as user_id, 
  DATEDIFF(orders.created_at, users.created_at) as days_since_signup
from
  orders
left join
  users on (users.id = orders.user_id)
where
  week(users.created_at) IN (#{@weeks.join(',')})
order by
  days_since_signup desc")

    # Organize them by cohort
    @purchases_by_week = {}
    orders_since_signup_query.each do |week, order_id, user_id, days_since_signup|
      @purchases_by_week[week] ||= []
      @purchases_by_week[week] << [user_id, days_since_signup]
    end

    # Organize each cohort into 7 day intervals
    @purchasers_by_week_with_intervals = {}
    @weeks.each do |week|
      next unless @purchases_by_week.has_key? week

      @purchasers_by_week_with_intervals[week] = {}
      max_days = @purchases_by_week[week].collect { |row| row[1] }.max
      intervals = (max_days / 7).ceil
      (0..intervals).to_a.each do |interval|
        @purchasers_by_week_with_intervals[week][interval] = 
          @purchases_by_week[week].select { |i| i[1] > interval && i[1] < interval + 7 }.uniq { |r| r[0] }.count
      end
    end

    # Find first time orders by cohort
    first_purchase_query = connection.execute(
"select 
  week(users.created_at), 
  users.id, 
  min(orders.created_at), 
  users.created_at, 
  DATEDIFF(min(orders.created_at), users.created_at) as days_until_purchase
from 
  orders
left join 
  users on (users.id = orders.user_id)
where 
  week(users.created_at) IN (#{@weeks.join(',')})
  AND users.created_at IS NOT NULL
group by
  users.id
order by
  days_until_purchase desc")

    # Organize first time purchases by week
    @firsts_by_week = {}
    first_purchase_query.each do |week, user_id, first_purchase, user_signed_up_at, days_until_purchase|
      @firsts_by_week[week] ||= []
      @firsts_by_week[week] << days_until_purchase
    end

    # Organize first time purchases into 7 day intervals
    @firsts_with_intervals = {}
    @longest_interval = 0
    @weeks.each do |week|
      @firsts_with_intervals[week] = {}

      max_days = @firsts_by_week[week].max
      intervals = (max_days / 7).ceil
      (0..intervals).to_a.each do |interval|
        @firsts_with_intervals[week][interval] = 
          @firsts_by_week[week].select { |i| i > interval && i < interval + 7}.count
      end
      @longest_interval = intervals if intervals > @longest_interval
    end

    @intervals = (0..@longest_interval).to_a
  end

private
  def connection
    ActiveRecord::Base.connection
  end
end
