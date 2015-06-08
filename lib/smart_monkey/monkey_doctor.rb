# coding: utf-8

module MonkeyDoctor

  def MonkeyDoctor.run_env_doctor
    doctor_list = []
    doctor_list << `hash idevice_id 2>/dev/null || { echo "Require 'libimobiledevice' but it's not installed. Please run 'brew install libimobiledevice' to install it."; exit 1; };`.strip
    doctor_list << `hash ideviceinstaller 2>/dev/null || { echo "Require 'ideviceinstaller' but it's not installed. Please run 'brew install ideviceinstaller' to install it."; exit 1; };`.strip
    doctor_list << `hash mogrify 2>/dev/null || { echo "Require 'imagemagick' but it's not installed. Please run 'brew install imagemagick' to install it."; exit 1; }; `.strip
    doctor_list.each do |item|
      if !item.empty?
        puts item
        exit(1)
      end
    end
  end

end
