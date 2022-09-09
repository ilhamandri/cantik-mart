class BackupsController < ApplicationController
  before_action :require_login
  
  def index
    refresh_files
    delete_old_files
    @backups = Backup.order("created DESC").page param_page
  end

  def download 
    id = params[:id]
    return redirect_back_data_error backups_path, "File tidak ditemukan" if id.nil?
    backup_file = Backup.find_by(id: id)
    return redirect_back_data_error backups_path, "File tidak ditemukan" if backup_file.nil?
    return redirect_back_data_error backups_path, "File tidak ditemukan" if !backup_file.present
    send_file("../../Backup/"+backup_file.filename)
  end

  private
    def delete_old_files
      file_names = Backup.all.order("created ASC").pluck(:filename)
      file_names.pop(5)
      file_names.each do |file_name|
        backup = Backup.find_by(filename: file_name)
        next if backup.nil?
        backup.present = false
        backup.save!
        path_to_file = "../../Backup/"+file_name
        File.delete(path_to_file) if File.exist?(path_to_file)
      end
    end

    def refresh_files
      Backup.update_all(present: false)
      files = Dir.glob("../../Backup/*")
      files.each do |file|
        file_size = convert_file_size File.size(file)
        file_name = file.gsub("../../Backup/", "")
        filre_created_epoch = (file_name.split("_")[1]).gsub(".bak", "")
        file_created = Time.at(filre_created_epoch.to_i).to_datetime
        
        backup_file = Backup.find_by(filename: file_name)
        if backup_file.nil?
          Backup.create filename: file_name, size: file_size, 
            created: file_created, present: true
        else
          backup_file.created = file_created
          backup_file.present = true
          backup_file.size = file_size
          backup_file.save!
        end
      end
    end

    def convert_file_size file_size
      kb = (file_size/1024.0).round(2)
      mb = (kb/1024.0).round(2)
      gb = (mb/1024.0).round(2)

      human_size = kb.to_s + " KB"

      if mb > 1
        human_size = mb.to_s + " MB"
      end

      if gb > 1 
        human_size = gb.to_s + " GB"
      end

      return human_size
    end

    def param_page
      params[:page]
    end
end