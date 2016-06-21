# coding: utf-8

module UIAutoMonkey
  require 'fileutils'
  require 'timeout'
  require 'rexml/document'
  require 'erubis'
  require 'json'

  class MonkeyRunner
    RESULT_BASE_PATH = File.expand_path('smart_monkey_result')
    INSTRUMENTS_TRACE_PATH = File.expand_path('*.trace')
    TIME_STAP = Time.new.strftime("%Y%m%d%H%M%S")

    include UIAutoMonkey::CommandHelper

    def run(opts)
      @options = opts
      if @options[:show_config]
        show_config
        return true
      elsif @options[:list_app]
        list_app
        return true
      elsif @options[:list_devices]
        list_devices
        return true
      elsif @options[:reset_iphone_simulator]
        reset_iphone_simulator
        return true
      end

      res_dir = @options[:result_base_dir] || RESULT_BASE_PATH
      puts "INSTRUMENTS_TRACE_PATH : #{INSTRUMENTS_TRACE_PATH}"
      puts "RESULT_BASE_PATH : #{res_dir}"

      ###########
      log @options.inspect
      FileUtils.remove_dir(result_base_dir, true)
      FileUtils.makedirs(result_base_dir)
      generate_ui_auto_monkey
      ###########
      start_time = Time.new.strftime("%Y-%m-%d %H:%M:%S")
      result_list = []
      total_test_count.times do |times|
        @times = times
        setup_running
        result = run_a_case
        finish_running
        result_list << result
      end
      create_index_html({
          :start_time => start_time,
          :end_time => Time.new.strftime("%Y-%m-%d %H:%M:%S"),
          :result_list => result_list,
          :ProductType => product_type(device),
          :ProductVersion => product_version(device),
          :UniqueDeviceID => device,
          :DeviceName => device_name(device),
          :Application => app_path
      })
      all_tests_ok?(result_list)
    end

    def setup_running
      kill_all_need
      # kill_all('iPhone Simulator')
      FileUtils.remove_dir(result_dir, true)
      ENV['UIARESULTSPATH'] = result_dir
      @crashed = false
      @no_run = false
      @uia_trace = false
    end

    def run_a_case
      log "=================================== Start Test (#{@times+1}/#{total_test_count}) ======================================="
      FileUtils.makedirs(crash_save_dir(@times+1)) unless File.exists?(crash_save_dir(@times+1))
      pull_crash_files(@times+1)
      cr_list = crash_report_list(@times+1)
      start_time = Time.now
      watch_syslog do
        begin
          unless time_limit_sec.nil?
            run_process(%W(instruments -w #{device} -l #{time_limit} -t #{automation_template_path} #{app_path} -e UIASCRIPT #{ui_custom_path} -e UIARESULTSPATH #{result_base_dir}))
          else
            run_process(%W(instruments -w #{device} -t #{automation_template_path} #{app_path} -e UIASCRIPT #{ui_custom_path} -e UIARESULTSPATH #{result_base_dir}))
          end
        rescue Timeout::Error
          kill_all('instruments', '9')
        end
      end

      pull_crash_files(@times+1)
      new_cr_list = crash_report_list(@times+1)
      # increase crash report?
      diff_cr_list = new_cr_list - cr_list
      
      if diff_cr_list.size > 0
        @crashed = true
        new_cr_name = File.basename(diff_cr_list[0]).gsub(/\.ips$/, '.crash')
        new_cr_path = File.join(result_dir, new_cr_name)
        log "Find new crash report: #{new_cr_path}"        
        if dsym_base_path != ''
          puts "Symbolicating crash report..."
          symbolicating_crash_report(diff_cr_list[0])
        end
        FileUtils.cp diff_cr_list[0], new_cr_path
      end
      # output result
      create_result_html(parse_results)

      {
        :start_time => start_time,
        :end_time => Time.now,
        :times => @times,
        :ok => !@crashed && !@no_run,
        :crash => @crashed,
        :result_dir => File.basename(result_history_dir(@times)),
        :message => nil
      }
    end

    def finish_running
      kill_all_need
      FileUtils.remove_dir(result_history_dir(@times), true)
      FileUtils.remove_dir(crash_save_dir(@times+1), true)
      FileUtils.move(result_dir, result_history_dir(@times))
      if @options[:compress_rate]
        compress_image(result_history_dir(@times))
      end
      rotate_imgs(result_history_dir(@times))
      rm_instruments_trace(INSTRUMENTS_TRACE_PATH)
      kill_all('iPhone Simulator')
      sleep 3
    end

    def create_index_html(result_hash)
      er = Erubis::Eruby.new(File.read(template_path('index.html.erb')))
      result_hash[:test_count] = result_hash[:result_list].size
      result_hash[:ok_count] = result_hash[:result_list].select {|r| r[:ok]}.size
      result_hash[:cr_count] = result_hash[:result_list].select {|r| r[:crash]}.size
      result_hash[:nr_count] = result_hash[:test_count] - result_hash[:ok_count] - result_hash[:cr_count]
      open("#{result_base_dir}/index.html", 'w') {|f| f.write er.result(result_hash)}
      copy_html_resources
      puts "Monkey Test Report:#{result_base_dir}/index.html"
    end
    
    def copy_html_resources
      bootstrap_dir = File.expand_path('../../bootstrap', __FILE__)
      FileUtils.copy("#{bootstrap_dir}/css/bootstrap.css", result_base_dir)
      FileUtils.copy("#{bootstrap_dir}/js/bootstrap.js", result_base_dir)
      FileUtils.copy(template_path('jquery.min.js'), result_base_dir)
    end

    def all_tests_ok?(result_list)
      result_list.select {|r| !r[:ok]}.empty?
    end

    def show_config
      puts File.read(config_custom_path)
    end

    def show_extend_javascript
      if @options[:extend_javascript_path]
        filename = @options[:extend_javascript_path]
        return File.exist?(filename), filename
      end
    end

    def list_app
      puts "============For iPhone Simulator:"
      puts find_apps('*.app').map{|n| File.basename n}.uniq.sort.join("\n")
      if !is_simulator
        puts "============For iPhone Device:"
        puts `ideviceinstaller -u #{device} -l`
      end
    end

    def list_devices
      puts devices.join("\n")
    end

    def log(msg)
      puts msg
    end

    def reset_iphone_simulator
      `killall -9 "iOS Simulator"`
      # FileUtils.rm_rf("#{Dir.home}/Library/Application\ Support/iPhone\ Simulator/")
      # puts 'reset iPhone Simulator successful'
    end

    def total_test_count
      (@options[:run_count] || 2)
    end

    def device
      if @options[:device]
        find_device(@options[:device])
      else
        (devices[0].strip.split("[")[1].split("]")[0])
      end
    end

    def app_path
      @app_path ||= find_app_path(@options)
    end

    def app_name
      File.basename(app_path).gsub(/\.app$/, '')
    end

    def find_apps(app)
      `"ls" -dt #{ENV['HOME']}/Library/Developer/Xcode/DerivedData/*/Build/Products/*/#{app}`.strip.split(/\n/)
    end

    def devices
      `"instruments" -s devices`.strip.split(/\n/).drop(2)
    end

    def find_device(device)
      device_line = `"instruments" -s devices | grep "#{device}"`.strip.split(/\n/)[0]
      if device_line.nil?
        puts "Invalid device, Please given a vaild device!"
        puts `"instruments" -s devices`
        exit(1)
      end
      # device_line.strip.split("[")[1].delete "] (Simulator)"
      device_line.strip.split("[")[1].split("]")[0]
    end

    def instruments_deviceinfo(device)
      `"instruments" -s devices | grep "#{device}"`.strip
    end

    def is_simulator
      deviceinfo = instruments_deviceinfo(device)
      if deviceinfo.include? "-"
        true
      else
        false
      end
    end

    def product_type(device)
      product_hash={
          "iPhone1,1"=>"iPhone",
          "iPhone1,2"=>"iPhone 3G",
          "iPhone2,1"=>"iPhone 3GS",
          "iPhone3,1"=>"iPhone 4 - GSM",
          "iPhone3,2"=>"iPhone 4 - CDMA",
          "iPhone3,3"=>"iPhone 4 - CDMA",
          "iPhone4,1"=>"iPhone 4S",
          "iPhone5,1"=>"iPhone 5",
          "iPhone5,2"=>"iPhone 5",
          "iPhone5,3"=>"iPhone 5C (GSM)",
          "iPhone5,4"=>"iPhone 5C (CDMA)",
          "iPhone6,1"=>"iPhone 5S (GSM)",
          "iPhone6,2"=>"iPhone 5S (CDMA)",
          "iPhone7,1"=>"iPhone 6 Plus",
          "iPhone7,2"=>"iPhone 6",
          "iPhone8,1"=>"iPhone 6S",
          "iPhone8,2"=>"iPhone 6S Plus",
          "iPad1,1"=>"iPad",
          "iPad2,1"=>"iPad 2 (Wi-Fi)",
          "iPad2,2"=>"iPad 2 (GSM)",
          "iPad2,3"=>"iPad 2 (CDMA)",
          "iPad2,4"=>"iPad 2 (Wi-Fi, revised)",
          "iPad2,5"=>"iPad mini (Wi-Fi)",
          "iPad2,6"=>"iPad mini (A1454)",
          "iPad2,7"=>"iPad mini (A1455)",
          "iPad3,1"=>"iPad (3rd gen, Wi-Fi)",
          "iPad3,2"=>"iPad (3rd gen, Wi-Fi+LTE Verizon)",
          "iPad3,3"=>"iPad (3rd gen, Wi-Fi+LTE AT&T)",
          "iPad3,4"=>"iPad (4th gen, Wi-Fi)",
          "iPad3,5"=>"iPad (4th gen, A1459)",
          "iPad3,6"=>"iPad (4th gen, A1460)",
          "iPad4,1"=>"iPad Air (Wi-Fi)",
          "iPad4,2"=>"iPad Air (Wi-Fi+LTE)",
          "iPad4,3"=>"iPad Air (Rev)",
          "iPad4,4"=>"iPad mini 2 (Wi-Fi)",
          "iPad4,5"=>"iPad mini 2 (Wi-Fi+LTE)",
          "iPad4,6"=>"iPad mini 2 (Rev)",
          "iPad4,7"=>"iPad mini 3 (Wi-Fi)",
          "iPad4,8"=>"iPad mini 3 (A1600)",
          "iPad4,9"=>"iPad mini 3 (A1601)",
          "iPad5,3"=>"iPad Air 2 (Wi-Fi)",
          "iPad5,4"=>"iPad Air 2 (Wi-Fi+LTE)",
          "iPod1,1"=>"iPod touch",
          "iPod2,1"=>"iPod touch (2nd gen)",
          "iPod3,1"=>"iPod touch (3rd gen)",
          "iPod4,1"=>"iPod touch (4th gen)",
          "iPod5,1"=>"iPod touch (5th gen)",
        }

      if is_simulator
        instruments_deviceinfo(device).split("[")[0]
      else
        type = `ideviceinfo -u #{device} -k ProductType`.strip
        product_hash[type]
      end
    end

    def product_version(device)
      if !is_simulator
        `ideviceinfo -u #{device} -k ProductVersion`.strip
      end
    end

    def device_name(device)
      if !is_simulator
        `ideviceinfo -u #{device} -k DeviceName`.strip
      end
    end

    def compress_image(path)
      puts 'Compress screenshot images...'
      compress_rate = @options[:compress_rate]
      # `find #{path} -name "*.png" -exec convert {} -resize 50% -sample 50% {} \\\;`
      `mogrify -resize #{compress_rate} "#{path}/*.png"`
    end

    def rotate_imgs(path)
      rotated_map={
          "1"=>nil,
          "2"=>"180",
          "3"=>"270",
          "4"=>"90",
      }
      orientation_file = File.join(result_base_dir,"orientation")
      if File.exists?(orientation_file)
        orientationNum = File.read(orientation_file).strip
        value = rotated_map[orientationNum]
        unless value.nil?
          `mogrify -rotate #{value} "#{path}/*.png"`
        end
      else
        exit(1)
      end
    end

    def kill_all_need
      kill_all('instruments', '9')
      kill_all('Instruments', '9')
      kill_all('idevicedebug', '9')
    end

    def find_app_path(opts)
      app_path = nil
      if opts[:app_path].include?('/')
        app_path = File.expand_path(opts[:app_path])
      elsif opts[:app_path] =~ /\.app$/
        apps = find_apps(opts[:app_path])
        app_path = apps[0]
        log "#{apps.size} apps are found, USE NEWEST APP: #{app_path}" if apps.size > 1
      else
        app_path = opts[:app_path]
        log "BundleID was found: #{app_path}"
      end
      
      unless app_path
        raise 'Invalid AppName'
      end
      app_path
    end

    def time_limit
      time_limit_sec * 1000
    end

    def time_limit_sec
      @options[:time_limit_sec]
    end

    def deviceconsole_original_path
      File.expand_path('../../ios_device_log/deviceconsole', __FILE__)
    end

    def ui_auto_monkey_lib_original_path
      File.expand_path('../../ui-auto-monkey', __FILE__)
    end

    def ui_auto_monkey_original_path
      File.expand_path('../../ui-auto-monkey/UIAutoMonkey.js', __FILE__)
    end

    def ui_custom_original_path
      File.expand_path('../../ui-auto-monkey/custom.js', __FILE__)
    end

    def ui_hole_handler_original_path
      File.expand_path('../../ui-auto-monkey/handler', __FILE__)
    end

    def ui_tuneup_original_path
      File.expand_path('../../ui-auto-monkey/tuneup', __FILE__)
    end

    def ui_auto_monkey_path
      "#{result_base_dir}/UIAutoMonkey.js"
    end

    def ui_custom_path
      "#{result_base_dir}/custom.js"
    end

    def dsym_base_path
      @options[:dsym_file_path] || ""
    end

    def xcode_developer_path
      `xcode-select --print-path`.strip
    end

    def xcode_path
      `dirname #{xcode_developer_path}`.strip
    end

    def automation_template_path
      `find #{xcode_path} -name Automation.tracetemplate`.strip
    end
    
    def symbolicatecrash_base_path()
      `find #{xcode_path} -name symbolicatecrash`.strip
    end

    def symbolicating_crash_report(crash_base_path)
      `DEVELOPER_DIR=#{xcode_developer_path} #{symbolicatecrash_base_path} -o #{crash_base_path} #{crash_base_path} #{dsym_base_path};wait;`
    end

    def result_base_dir
      File.join(@options[:result_base_dir] || RESULT_BASE_PATH, "report_#{TIME_STAP}")
    end

    def crash_save_dir(times)
      "#{result_base_dir}/crash_#{times}"
    end

    def result_dir
      "#{result_base_dir}/Run 1"
    end

    def result_history_dir(times)
      "#{result_base_dir}/result_#{sprintf('%03d', times)}"
    end

    def sim_crash_report_dir
      "#{ENV['HOME']}/Library/Logs/DiagnosticReports"
    end

    def pull_crash_files(times)
      if !is_simulator
        `idevicecrashreport -u #{device} -e -k #{crash_save_dir(times)}`
      else
        `cp #{sim_crash_report_dir}/* #{crash_save_dir(times)}`
      end
    end

    def crash_report_list(times)
      # ios version >7.0  => *.ips
      `ls -t #{crash_save_dir(times)}/*.crash 2>&1;ls -t #{crash_save_dir(times)}/*.ips 2>&1;`.strip.split(/\n/)
      # `ls -t #{crash_save_dir}/#{app_name}_*.crash`.strip.split(/\n/)
    end

    def rm_instruments_trace(traces)
      `rm -rf #{traces}`
    end

    def grep_ios_syslog
      if is_simulator
        puts "Attempting iOS Simulator system log capture via tail system.log."
        "tail -n 0 -f ~/Library/Logs/CoreSimulator/#{device}*/system.log"
      else
        puts "Attempting iOS device system log capture via deviceconsole."
        "#{deviceconsole_original_path} -u #{device}"
      end
    end

    def console_log_path
      "#{result_dir}/console.txt"
    end

    def uiautomation_xsl_path
      File.expand_path("../templates/automation_result.xsl", __FILE__)
    end

    def template_path(name)
      File.expand_path("../templates/#{name}", __FILE__)
    end

    def parse_uiautomation_plist
      `xsltproc --output "#{result_dir}/uiautomation.html" #{uiautomation_xsl_path} "#{result_dir}/Automation Results.plist"`
    end

    def replace_event_num_for_time_limit(custom_file)
      File.open(custom_file) do |fr|
        buffer = fr.read.gsub(/monkey.config.numberOfEvents.*;/, "monkey.config.numberOfEvents = 99999999;")
        File.open(custom_file, "w") { |fw| fw.write(buffer) }
      end
    end

    def replace_event_num_for_user_define(custom_file, event_number)
      File.open(custom_file) do |fr|
        buffer = fr.read.gsub(/monkey.config.numberOfEvents.*;/, "monkey.config.numberOfEvents = #{event_number};")
        File.open(custom_file, "w") { |fw| fw.write(buffer) }
      end
    end

    def generate_ui_auto_monkey
      # extend_javascript_flag, extend_javascript_path =  show_extend_javascript
      # orig = File.read(ui_custom_original_path)
      # config = JSON.parse(File.read(config_json_path))
      # replace_str = "    this.config = #{JSON.pretty_generate(config, :indent => ' '*6)}; \n"
      # js = replace_text(orig, replace_str, '__UIAutoMonkey Configuration Begin__', '__UIAutoMonkey Configuration End__')
      # if extend_javascript_flag
      #   js = File.read(extend_javascript_path) + "\n" + js
      # end
      envs_str="UniqueDeviceID=\"#{device}\";\nResultBaseDir=\"#{result_base_dir}\";\n"
      File.open(File.join(result_base_dir,"Env.js"), 'w') {|f| f.write(envs_str)}
      if @options[:custom_cfg_path]
        FileUtils.cp_r(File.join(@options[:custom_cfg_path], "."), result_base_dir)
        FileUtils.copy(ui_auto_monkey_original_path, result_base_dir)
        FileUtils.cp_r(ui_tuneup_original_path, result_base_dir)
      else
        FileUtils.cp_r(File.join(ui_auto_monkey_lib_original_path, "."), result_base_dir)
      end
      replace_event_num_for_user_define(ui_custom_path, @options[:event_number]) if @options[:event_number]
      replace_event_num_for_time_limit(ui_custom_path) unless time_limit_sec.nil?
    end

    def config_custom_path
      if @options[:custom_cfg_path]
        File.join(@options[:custom_cfg_path], "custom.js")
      else
        ui_custom_original_path
      end
    end

    def replace_text(orig, replace_str, marker_begin_line, marker_end_line)
      results = []
      status = 1
      orig.each_line do |line|
        if status == 1 && line =~ /#{marker_begin_line}/
          status = 2
          results << line
          results << replace_str
        elsif status == 2 && line =~/#{marker_end_line}/
          status = 3
        end
        results << line unless status == 2
      end
      results.join('')
    end

    def parse_results
      filename = "#{result_dir}/Automation Results.plist"
      log_list = []
      if File.exists?(filename)
        doc = REXML::Document.new(open(filename))
        doc.elements.each('plist/dict/array/dict') do |record|
          ary = record.elements.to_a.map{|a| a.text}
          log_list << Hash[*ary]
        end
        parse_uiautomation_plist
        @uia_trace = true
      end
      @no_run = true if log_list.empty? || log_list[-1][MESSAGE] =~ /target application is not frontmost/
      log_list
    end

    def create_result_html(log_list)
      latest_list = LogDecoder.new(log_list).decode_latest(@options[:detail_event_count], @options[:drop_useless_img], result_dir)
      hash = {}
      hash[:log_list] = latest_list.reverse
      hash[:log_list_json] = JSON.dump(hash[:log_list])
      crash_report = Dir.glob("#{result_dir}/*.crash")[0]
      hash[:crash_report] = crash_report ? File.basename(crash_report) : nil
      hash[:uia_trace] = @uia_trace
      hash[:crashed] = @crashed
      hash[:no_run] = @no_run
      er = Erubis::Eruby.new(File.read(template_path('result.html.erb')))
      open("#{result_dir}/result.html", 'w') do |f|
        f.write(er.result(hash))
      end
      FileUtils.copy(template_path('result_view.js'), "#{result_dir}/result_view.js")
    end

    def watch_syslog
      STDOUT.sync = true
      stdin, stdout, stderr = Open3.popen3(grep_ios_syslog)
      log_filename = "#{result_base_dir}/console.txt"
      thread = Thread.new do
        File.open(log_filename, 'a') do |output|
          begin
            while true
              line = stdout.readline
              output.write(line) 
              # output.write(line) if line.include?(app_name)
            end
          rescue IOError
            log 'Stop iOS system log capture.'
            kill_all_need
          end
        end
      end
      yield
      sleep 3
      stdout.close; stderr.close; stdin.close
      thread.join
      FileUtils.makedirs(result_dir) unless File.exists?(result_dir)
      if File.exists?(log_filename)
        FileUtils.move(log_filename, console_log_path)
      end
    end
  end

  LOG_TYPE = 'LogType'
  MESSAGE = 'Message'
  TIMESTAMP = 'Timestamp'
  SCREENSHOT = 'Screenshot'

  class LogDecoder
    def initialize(log_list)
      @log_list = log_list
    end

    def rm_unused_imgs(used_imgs, dir)
      used_strs = used_imgs.join("\\|")
      `cd "#{dir}";find . -type 'f' -name '*.png' | grep -v "#{used_strs}" | xargs -I{} rm {}`
    end

    def decode_latest(num=10, drop_useless_img, drop_dir)
      hash = {}
      ret = []
      used_imgs = []
      @log_list.reverse.each do |log|
        break if num == 0
        if log[LOG_TYPE] == 'Screenshot'
          if log[MESSAGE] =~ /^action/
            hash[:action_image] = log[MESSAGE]
          elsif log[MESSAGE] =~ /^monkey[^external]*$/
            hash[:screen_image] = log[MESSAGE]
            used_imgs << log[MESSAGE]
            hash[:timestamp] = log[TIMESTAMP]
            
            # emit and init
            if block_given?
              yield(hash)
            else
              ret << hash
            end
            hash = {}
            num -= 1
          end
        elsif log[LOG_TYPE] == 'Debug' && log[MESSAGE] =~ /^target./
          # hash[:message] = log[MESSAGE] unless log[MESSAGE] =~ /^target.captureRectWithName/ && log[MESSAGE] =~ /switcherScrollView/
          hash[:message] = log[MESSAGE] unless log[MESSAGE] =~ /size:{height:0.00,width:0.00}/ || log[MESSAGE] =~ /switcherScrollView/
        end
      end
      #drop unused imgs
      if drop_useless_img
        puts "Drop useless images..."
        rm_unused_imgs(used_imgs, drop_dir)
      end
      if !@log_list.empty?
        #add screen_size
        hash = {}
        hash[:screen_size] = @log_list[0][MESSAGE]
        ret << hash
      end
      ret
    end
  end
end
