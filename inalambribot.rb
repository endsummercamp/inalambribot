#!/usr/bin/env ruby

require 'telegram/bot'
require 'csv'
require 'fileutils'

token = ENV['BOT_TOKEN']

CSV_DIR = File.expand_path('csv', __dir__)
CSV_PATH = File.join(CSV_DIR, 'esc_wifi.csv')
LOCK_PATH = File.join(CSV_DIR, '.esc_wifi.lock')

CSV.read(CSV_PATH, headers: true)

def sanitize_username(username)
  username.to_s.gsub(/[^A-Za-z0-9_-]/, '_')
end

def assign_password(username)
  File.open(LOCK_PATH, File::CREAT | File::RDWR) do |lock|
    lock.flock(File::LOCK_EX)

    table = CSV.read(CSV_PATH, headers: true)
    headers = table.headers

    existing = table.find { |row| row['User Role'] == username }
    return existing['Passphrase'] if existing

    free_row = table.find { |row| row['User Role'].nil? && row['VLAN ID'].to_i < 200 }
    return nil unless free_row

    free_row['User Role'] = username

    tmp_path = "#{CSV_PATH}.tmp"
    CSV.open(tmp_path, 'w') do |csv|
      csv << headers
      table.each { |row| csv << row }
    end
    File.rename(tmp_path, CSV_PATH)

    FileUtils.cp(CSV_PATH, File.join(CSV_DIR, "esc_wifi_#{sanitize_username(username)}.csv"))

    free_row['Passphrase']
  end
end

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    if message.chat.type == "private"
      case message.text
      when '/start'
        user_info = bot.api.get_chat_member(chat_id: ENV['ESC_GROUP_ID'], user_id: message.chat.id)
        if !["left", "kicked"].include?(user_info.status)
          username = message.chat.username.nil? ? message.chat.id.to_s : message.chat.username
          password = assign_password(username)
          if password
            bot.api.send_message(chat_id: message.chat.id, text: "Ciao, #{message.from.first_name.sub('_', '\_')}\nBenvenuto all'ESC!\nQuesta è la tua password del wireless: `#{password}`", parse_mode: 'Markdown')
          else
            bot.api.send_message(chat_id: message.chat.id, text: "Ciao, #{message.from.first_name}.\nMi spiace, al momento non ci sono più password disponibili.")
          end
        else
          bot.api.send_message(chat_id: message.chat.id, text: "Ciao, #{message.from.first_name}.\nSfortunatamente non sei membro del gruppo o sei stat* bannat*, per cui non puoi ottenere una password del WiFi.")
        end
      when '/stop'
        bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
      when '/antani'
        bot.api.send_message(chat_id: message.chat.id, text: "Come se fosse antani, #{message.from.first_name}, prematurata la supercazzola con scappellamento a destra o scherziamo?")
      end
    end
  end
end
