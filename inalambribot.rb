#!/usr/bin/env ruby

require 'telegram/bot'
require 'csv'
require 'fileutils'

token = ENV['BOT_TOKEN']

# load CSV
credentials = []
headers = nil
CSV.foreach("csv/esc_wifi.csv", headers: true) do |row|
  headers ||= row.headers
  credentials << row
end

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    if message.chat.type == "private"
      case message.text
      when '/start'
        user_info = bot.api.get_chat_member(chat_id: ENV['ESC_GROUP_ID'], user_id: message.chat.id)
        if !["left", "kicked"].include?(user_info.status)
          username = message.chat.username.nil? ? message.chat.id : message.chat.username
          password = nil
          credentials.each do |curcred|
            if curcred["User Role"] == username 
              password = curcred["Passphrase"]
              break
            end
            if curcred["User Role"].nil?
              if curcred["VLAN ID"].to_i < 200
                password = curcred["Passphrase"]
                curcred["User Role"] = username
                CSV.open("csv/esc_wifi_new.csv", "w") do |csv|
                  csv << headers
                  credentials.each do |credential|
                    csv << credential
                  end
                end
                FileUtils.cp "csv/esc_wifi_new.csv", "csv/esc_wifi_#{username}.csv"
                FileUtils.mv "csv/esc_wifi_new.csv", "csv/esc_wifi.csv"
                break
              end
            end
          end
          bot.api.send_message(chat_id: message.chat.id, text: "Ciao, #{message.from.first_name}\nBenvenuto all'ESC!\nQuesta è la tua password del wireless: #{password}")
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
