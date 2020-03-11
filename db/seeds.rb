# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

require 'rest-client'
require 'json'

def getHolidays(year)
  for i in 0..20
    #creates year and finds id
    Year.create(year: year + i)
    year_id = Year.find_by(year: year + i)['id']

    #get request to 3rd party api and parses
    response_string = RestClient.get("https://calendarific.com/api/v2/holidays?&api_key=#{ENV['api_key']}&country=US&year=#{year + i}")
    response_hash = JSON.parse(response_string)

    #grabbing the specific holiday object that's needed
    holiday_array = response_hash['response']['holidays']

    #searches object for national holidays and saves into database
    seedHolidays(holiday_array, year_id)
  end
end

def seedHolidays(holidays, year_id)
  holidays.each do |holiday_object|
    if holiday_object['type'].include?('National holiday')
      holiday_date = holiday_object['date']['datetime']
      Holiday.create(
                     year_id: year_id,
                     name: holiday_object['name'],
                     yr: holiday_date['year'],
                     day: holiday_date['day'],
                     month: holiday_date['month']
                    )
    end
  end
end

getHolidays(2020)
