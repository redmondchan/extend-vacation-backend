class YearsController < ApplicationController

  # finds the day of week
  def find_day_of_week(date)
    day_of_week = Date.new(date['yr'], date['month'], date['day']).wday
    return day_of_week
  end

  # calculates the last day of the vacation
  def find_end_date(month, pto, year, first_run)
    #checks for next year
    if month == 13
      month = 1
      year+= 1
    end

    # checks for leap year
    leap_year = false
    if year%4 == 0 && year%100 == 0 && year%400 == 0
      leap_year = true
    elsif year%4 == 0 && year%100 != 0
      leap_year = true
    end

    # checks for February
    if month == 2
      if leap_year == true
        if pto > 29
          pto -= 29
          month += 1
          return find_end_date(month, pto, year, true)
        else
          return {"month" => month, "day" => pto, "yr" => year}
        end
      else
        if pto > 28
          pto -= 28
          month += 1
          return find_end_date(month, pto, year, true)
        else
          # if the end date is a friday, saturday or sunday, add 2 extra days
          if [0,5,6].include?(find_day_of_week({"month" => month, "day" => pto, "yr" => year})) && first_run
            return find_end_date(month, pto + 2, year, false)
          end
          return {"month" => month, "day" => pto, "yr" => year}
        end
      end
    end

    #checks for months with 30 days
    if [4,6,9,11].include?(month)
      if pto > 30
        pto -= 30
        month += 1
        return find_end_date(month, pto, year, true)
      else
        # if the end date is a friday, saturday or sunday, add 2 extra days
        if [0,5,6].include?(find_day_of_week({"month" => month, "day" => pto, "yr" => year})) && first_run
          return find_end_date(month, pto + 2, year, false)
        end
        return {"month" => month, "day" => pto, "yr" => year}
      end
    end

    #checks for months with 31 days
    if [1,3,5,7,8,10,12].include?(month)
      if pto > 31
        pto -= 31
        month += 1
        return find_end_date(month, pto, year, true)
      else
        # if the end date is a friday, saturday or sunday, add 2 extra days
        if [0,5,6].include?(find_day_of_week({"month" => month, "day" => pto, "yr" => year})) && first_run
          return find_end_date(month, pto + 2, year, false)
        end
        return {"month" => month, "day" => pto, "yr" => year}
      end
    end
    #last end for find_end date
  end

  # calculates total # of days from the start to end date
  def days_until_last(days, start_date, end_date)
    #checks for leap year
    year = end_date['yr']
    leap_year = false
    if year%4 == 0 && year%100 == 0 && year%400 == 0
      leap_year = true
    elsif year%4 == 0 && year%100 != 0
      leap_year = true
    end


    for i in start_date['month']..end_date['month']
      # removes the days that passed in the starting month and adds the days that passed in the ending month
      if i == end_date['month']
        days += end_date['day']
        days -= start_date['day'] - 1
        return days
        #adds the number of days for each month
      else
        # checks for February
        if end_date['month'] == 2 && leap_year
          days += 29
        elsif  end_date ['month'] == 2 && !leap_year
          days += 28
        end

        #checks for months with 30 days
        if [4,6,9,11].include?(i)
          days += 30
        end

        # checks for months with 31 days
        if [1,3,5,7,8,10,12].include?(i)
          days += 31
        end
      end
    end
    #final closure for days_until_last
  end

  #finds the total number of holidays that overlap with the vacation duration
  def find_overlap(start_date, end_date, object)
    #finds the holidays of that year

    holidays = Year.find_by(year: start_date['yr']).holidays
    #removes the holidays that occur before the start date
    index = holidays.index(start_date)
    length = holidays.length
    filtered_holidays = holidays.slice(index, length)

    weekday_holidays = []
    holiday_names = []

    #filter holidays that occur on a weekday
    for i in 0...filtered_holidays.length
      day_of_week = find_day_of_week(filtered_holidays[i])
      if day_of_week != 0 && day_of_week != 6
        weekday_holidays.push(filtered_holidays[i])
      elsif holidays[i] == start_date
        weekday_holidays.push(filtered_holidays[i])
      end
    end

    #add all the holidays for that year if the start year and end year are not the same
    if start_date['yr'] != end_date['yr']
      object['count'] += weekday_holidays.length
      new_year = start_date['yr'] + 1
      new_start_date = Year.find_by(year: new_year).holidays[0]
      return find_overlap(new_start_date, end_date, object)
    end

    #adds holidays when start year and end year is the same
    count = object['count']
    if start_date['yr'] == end_date['yr']
      weekday_holidays.each do |holiday|
        #adds holiday if it's in the same month as the end date
        if holiday['month'] == end_date['month'] && end_date['day'] >= holiday['day'] && !object.include?(holiday['name'])
          count += 1
          object['names'].push(holiday['name'])
        #adds holiday that occur during the months before the end date
        elsif  end_date['month'] > holiday['month'] && !object['names'].include?(holiday['name'])
          count += 1
          object['names'].push(holiday['name'])
        end
      end

      #recalculate if there are more overlap holidays after adding overlap holidays
      # binding.pry
      count = object['count']
      if count > object['count']
        pto = days_until_last(count - 1, start_date, end_date)
        new_end_date = find_end_date(start_date['month'], pto, end_date['yr'], true)
        # if count == 1
        #   return find_overlap(start_date, new_end_date, {"count" => count - 1, "names" => object['names']})
        # else
          return find_overlap(start_date, new_end_date, {"count" => count - 1, "names" => object['names']})
        # end
      end

      #if none of the conditions above are true, it'll return the count because it's calculated all overlapping holidays
      return object['count']
    end
  end

  def calculate(holiday, pto)
    #finds the day of the week the holiday lands on
    day_of_week = find_day_of_week(holiday)

    #checks if holiday is monday, if yes, starts vacation on the weekend, if no ,sets start_day to the holiday
    #what if it's new years on a monday???
    start_date = 0
    if day_of_week == 1
      start_day = holiday['day'] - 2
    else
      start_day = holiday['day']
    end

    # if vacation begins on saturday, add an extra pto day for sunday???
    if day_of_week == 6
      pto += 1
    end

    # calculates the # of weekends
    weekends = (pto/5).floor
    #adds the total # of days based on # of pto starting from the first day of the month
    # Ex: 2/16/2020 start date with 10 pto would give us 26
    total_days = holiday['day'] + pto + (weekends * 2)
    # calculates the last day of the vacation
    end_date = find_end_date(holiday['month'], total_days, holiday['yr'], true)
    # finds overlapping holidays
    count_object = {"count" => 0, "names" => []}
    overlap = find_overlap(holiday, end_date, count_object)
    # recalculates the last day of the vacation by adding the # of overlapping holidays to pto
    new_end_date = find_end_date(holiday['month'], total_days + overlap, holiday['yr'], true)

    #if the new end date lands on a saturday, add another day to end on Sunday
    if find_day_of_week(new_end_date) == 6
      new_end_date = find_end_date(holiday['month'], total_days + overlap + 1, holiday['yr'])
    end

    #if the new end date lands on a friday, add two days to end on Sunday
    if find_day_of_week(new_end_date) == 5
      new_end_date = find_end_date(holiday['month'], total_days + overlap + 2, holiday['yr'])
    end

    # returns a string of the duration Ex: 1/1/2020 - 2/5/2020
    # binding.pry
    return "#{holiday['month']}/#{start_day}/#{holiday['yr']} - #{new_end_date['month']}/#{new_end_date['day']}/#{new_end_date['yr']}"
  end

  #calculates the vacation for each holiday of the year
  def calculate_vacation(year, pto)
    array = []
    holidays = Year.find_by(year: year).holidays

    weekday_holidays = []

    # filters holidays that land on a weekday
    holidays.each do |holiday|
      if ![0,6].include?(find_day_of_week(holiday)) && holiday['name'] != "New Year's Day observed"
        weekday_holidays.push(holiday)
      end
    end

    # calculate each weekday holiday vacation duration
    weekday_holidays.each do |holiday|
      array.push(calculate(holiday, pto))
    end

    return array
  end

  def create
    year = Year.find_by(year: year_params[:year])
    @results = Result.where(year_id: year, pto: params[:pto])

    if @results.length == 0
      array = calculate_vacation(year_params[:year], year_params[:pto])
      array.each do |vacation|
        Result.create(
          year_id: year.id,
          pto: params[:pto],
          result: vacation
        )
      end
      @results = Result.where(year_id: year, pto: year_params[:pto])
    end

    render json: {result: @results}
  end


  private

  def year_params
    params.require(:year).permit(:year, :pto)
  end


end
