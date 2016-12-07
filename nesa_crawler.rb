require 'mechanize'
require 'io/console'


if STDIN.respond_to?(:noecho)
  def get_password()
    print "Password: "
    STDIN.noecho(&:gets).chomp
  end
else
  puts "[Warning] Unsafe Password Entry"
  def get_password()
    print "Password (Will be visible, watch out!): "
    gets.chomp
  end
end

time = Time.now
puts "Connecting..."
bot = Mechanize.new{|a|a.verify_mode = OpenSSL::SSL::VERIFY_NONE}
bot.get("https://kss.nesa-sg.ch/loginto.php?mode=0&lang=") do |page|
  puts "Connected! (took #{Time.now-time} sec)"
  print "Username: "
  user = gets.chomp
  password = get_password()
  full_name = user.split(".").map(&:capitalize).join(" ")
  puts
  puts "Fetching Data..."

  form = page.form("standardformular")
  form.login = user
  form.passwort = password
  #Navigating
  page = bot.submit(form)
  page = bot.page.link_with(:text => 'Noten').click

  grades = Hash.new
  grades_rounded = Hash.new
  page.search("table.list > tr").each do |tr|
    items = tr.search("td").collect {|text| text.to_s}
    unless items[0].nil?||items[1].nil? then
      subject = items[0].to_s[/(\w{1,5}(?=-[1-4]))|f{2}\w*/]
      grade_string = items[1].to_s.sub(/onmouseover=".*"/,"")[/([1-6]\.[0-9]{3})|---/]
      grades[subject] = grade_string
    end
  end

  points = 0
  grades.each do |subject,grade_string|

    grade = (2*grade_string.to_f).round.to_f / 2
    next if /SPO/ === subject || grade==0.0
    rel_grade=if grade>=4 then grade-4 else (grade-4)*2 end

    puts "#{subject} : #{grade} ; #{rel_grade} "
    points+=rel_grade

    grades_rounded[subject.to_sym]=grade
  end
  #puts grades, grades_rounded
  puts "Promotion points: #{points}"
end
