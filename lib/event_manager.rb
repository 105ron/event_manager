require 'csv'
require 'sunlight/congress'
require 'erb'
require 'date'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id,form_letter)
  Dir.mkdir("output") unless Dir.exists?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

def clean_phone(phone)
  phone = phone.gsub(/[^\d]/, '')
  if phone.length == 11 && phone[0] == "1"
    phone[1..11]
  elsif phone.length > 10 #Catches 11 digits and first character not "1"
    default_number
  elsif phone.length < 10
    default_number
  else
    phone
  end
end


def default_number
  "5555555555"
end


def registered_time(time)
  DateTime.strptime(time, '%m/%e/%y %k:%M')
end


def sort_times(times)
  hash = {}
  times.each do |time|
    if hash.has_key?(time) #If it already has key add one to the value
        hash[time] += 1
    else
      hash[time] = 1 #else create key with value 1
    end
  end
  hash.map.sort_by {|key, value| value}.reverse
end

puts "EventManager initialized."

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter
register_hours = Array.new
register_days = Array.new
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  phone = clean_phone(row[:homephone])
  register_date = registered_time(row[:regdate])
  register_hours << register_date.strftime('%H')
  register_days << register_date.strftime('%A')
  puts register_date.strftime('%H')
  form_letter = erb_template.result(binding)

  save_thank_you_letters(id,form_letter)
end
sort_times(register_hours)
sort_times(register_days)