#!/usr/bin/env ruby

# Sample Retrospect Event Handler
# 
#     The Retrospect application will call this batch file with the first
# argument as the subroutine name (e.g. "EndSource").
#     Events supported by Retrospect (See the methods below for the arguments
# passed in for each event.)
# StartApp -- Retrospect has been launched
# EndApp -- Retrospect is quitting
# StartBackupServer - The backup server is starting
# StopBackupServer - The backup server is stopping
# StartScript - A script is beginning
# EndScript - A script is stopping
# StartSource - A volume is about to be backed up
# EndSource - A volume has been backed up
# 
# MediaRequest - Retrospect needs media.
# TimedOutMediaRequest - If "Media Request Times Out" is set in "Special-Preferences"
#     then this message is sent before timing out. Return an error to cause
#     Retrospect to reset its timer.
# 
# ScriptCheckFailed - Called before Retrospect quits if the next scheduled
#     script will not be able to run (due to no media or other conditions).
# NextExec - Called before Retrospect quits with the name and start date of
#     the next script that will be able to run.
# 
# StopSched - Called when a script has a scheduled interval to run before the
#     interval has elapsed. Return an error to cause Retrospect to continue
#     executing the script.
# 
# PasswordEntry - Called whenever a password is entered.
# FatalBackupError - Called whenever an un-recoverable error occurs. (i.e hardware 
# 	failure)
# 
# (C) Retrospect, Inc.
# 


# To test this script, run the following in the terminal:
# > cd "/Library/Application Support/Retrospect/"
# > retroEventHandler.rb StartApp "2/10/2016 12:01 AM" "true"

def main
  if (ARGV[0])
    event = ARGV[0].to_sym       # StartApp, EndApp, StartScript, etc.
  else
    puts "This is a sample Retrospect external script written in ruby."
    puts "It will display a message for each Retrospect event."
    puts ""
    puts "To use this file on the backup server, move it to:"
    puts "/Library/Application Support/Retrospect/"
    return
  end
  
  event_handler = EventHandler.new
  
  # uncomment the following line to see all parameters passed into this script
  # event_handler.printParameters()
  
  event_handler.public_send(event)
end

class EventHandler
  def log message
    # Messages will go to the following log file
    logFile = "~/Desktop/eventhandler_log.txt"
    File.open(File.expand_path(logFile), "a") {
      |f| f.write("#{message}\n")
    }
  end
  
  def abort_with_msg interventionFile, message
    # will write the message to the log file and abort the event, if possible
    begin
      File.open(File.expand_path(interventionFile), "a") {|f| 
        f.write(message)
      }
      log message
    rescue Exception => e
      log "Error aborting Retrospect event: #{e.inspect}}"
    end
    Kernel.exit(1)
  end

  def printParameters
    str = ""
    ARGV.each { |arg|
        str += "\"#{arg}\" "
    }
    log str
  end

  def StartApp
    eventDate = ARGV[1]         # e.g. 2/10/2017 15:39
    autoLaunched = ARGV[2]      # Always true for Mac engine
    interventionFile = ARGV[3]  # Anything written to this file will be written to the log and cause Retrospect to cancel
    log "StartApp: starting on #{eventDate}, autoLaunched: #{autoLaunched}"
  
    # To cancel Retrospect event
    # abort_with_msg interventionFile, "Launch cancelled by RetroEventHandler.rb"
  end
  
  def EndApp
    eventDate = ARGV[1]
    log "EndApp: exiting on #{eventDate}"
  end
  
  def StartBackupServer
    eventDate = ARGV[1]         # e.g. 2/10/2017 15:39
    interventionFile = ARGV[2]  # Anything written to this file will be written to the log and cause Retrospect to cancel
    log "StartBackupServer: starting on #{eventDate}"
  
    # To cancel Retrospect event
    # abort_with_msg interventionFile, "Proactive backup cancelled by RetroEventHandler.rb"
  end
  
  def StopBackupServer
    eventDate = ARGV[1]         # e.g. 2/10/2017 15:39
    log "StopBackupServer: stopping on #{eventDate}"
  end
  
  def StartScript
    scriptName = ARGV[1]
    eventDate = ARGV[2]         # e.g. 2/10/2017 15:39
    interventionFile = ARGV[3]  # Anything written to this file will be written to the log and cause Retrospect to cancel
    log "Retrospect script #{scriptName} starting on #{eventDate}"
  
    # To cancel Retrospect event
    # abort_with_msg interventionFile, "Script #{scriptName} cancelled by RetroEventHandler.rb"
  end
  
  def EndScript
    scriptName = ARGV[1]
    numErrors = ARGV[2].to_i
    fatalErrCode = ARGV[3].to_i
    fatalErrMsg = ARGV[4]
    if fatalErrCode
      log "Retrospect script #{scriptName} stopped with error #{fatalErrCode} - #{fatalErrMsg}."
    elsif numErrors
      log "Retrospect script #{scriptName} stopped with #{numErrors} errors."
    else
      log "Retrospect script #{scriptName} stopped with no errors."
    end
  end
  
  def StartSource
    scriptName = ARGV[1]
    volName = ARGV[2]
    sourcePath = ARGV[3]
    clientName = ARGV[4]
    interventionFile = ARGV[5]  # Anything written to this file will be written to the log and cause Retrospect to cancel
    if clientName.to_s.length > 0 then
      log "Retrospect script #{scriptName} backing up volume #{volName} at #{sourcePath} on #{clientName}."
    else
      log "Retrospect script #{scriptName} backing up volume #{volName} at #{sourcePath}."
    end
  
    # To cancel Retrospect event
    # abort_with_msg interventionFile, "Backup of source #{volName} cancelled by RetroEventHandler.rb"
  end
  
  def EndSource
    ndex = 0
    scriptName = ARGV[ndex += 1]
    sourceName = ARGV[ndex += 1]
    sourcePath = ARGV[ndex += 1]
    clientName = ARGV[ndex += 1]
    kbBackedUp = ARGV[ndex += 1]
    numFiles = ARGV[ndex += 1]
    duration = ARGV[ndex += 1]
    sourceStart = ARGV[ndex += 1]
    sourceEnd = ARGV[ndex += 1]
    scriptStart = ARGV[ndex += 1]
    backupSet = ARGV[ndex += 1]
    backupAction = ARGV[ndex += 1]
    parentVol = ARGV[ndex += 1]
    numErrors = ARGV[ndex += 1].to_i
    fatalErrCode = ARGV[ndex += 1].to_i
    fatalErrMsg = ARGV[ndex += 1]
    
    if fatalErrCode != 0
      log "Retrospect script #{scriptName}, backing up #{sourceName} at #{sourcePath} to #{backupSet}, was stopped with error #{fatalErrCode} - #{fatalErrMsg}."
    elsif numErrors > 0
      log "Retrospect script #{scriptName}, backed up #{sourceName} at #{sourcePath} to #{backupSet} with #{numErrors} errors."
    else
      log "Retrospect script #{scriptName}, backed up #{sourceName} at #{sourcePath} to #{backupSet} successfully."
    end
  end

  # Media Request and other housekeeping events

  def MediaRequest
    ndex = 0
    backupSet = ARGV[ndex += 1]
    memberName = ARGV[ndex += 1]
    mediaIsKnown = ARGV[ndex += 1]
    waited = ARGV[ndex += 1]
    interventionFile = ARGV[ndex += 1]
    
    log "Retrospect is requesting media #{memberName} from #{backupSet}."

    # To cancel Retrospect event
    # abort_with_msg interventionFile, "Media Request for #{mediaName} cancelled by RetroEventHandler.rb"
  end

  def TimedOutMediaRequest
    ndex = 0
    backupSet = ARGV[ndex += 1]
    memberName = ARGV[ndex += 1]
    mediaIsKnown = ARGV[ndex += 1]
    waited = ARGV[ndex += 1]
    interventionFile = ARGV[ndex += 1]
    log "Retrospect's request for media #{memberName} from #{backupSet} is about to time out after waiting #{waited} minutes."

    # In this case, cancelling means, reset the media request to try again
    # abort_with_msg interventionFile, "Media Request timeout for #{mediaName} was cancelled by RetroEventHandler.rb"
  end

  def ScriptCheckFailed
    ndex = 0
    scriptName = ARGV[ndex += 1]
    startDate = ARGV[ndex += 1]
    reason = ARGV[ndex += 1]
    errCode = ARGV[ndex += 1]
    errMsg = ARGV[ndex += 1]
    
    log "Script #{scriptName} will not run on #{startDate}:#{reason} (#{errCode} - #{errMsg})"
  end
  
  def NextExec
    ndex = 0
    scriptName = ARGV[ndex += 1]
    startDate = ARGV[ndex += 1]
    
    log "Script #{scriptName} is scheduled to run on #{startDate}."
  end

  def StopSched
    # A script is hitting its scheduled stop time
    ndex = 0
    scriptName = ARGV[ndex += 1]
    startDate = ARGV[ndex += 1]
    interventionFile = ARGV[ndex += 1]
    
    log "Script #{scriptName} is scheduled to stop on #{startDate}."

    # In this case, cancelling means, letting the script continue
    # abort_with_msg interventionFile, "Script #{scriptName} was told to continue to run by RetroEventHandler.rb"
  end

  def PasswordEntry
    # Someone tried to log into Retrospect, a client, backup set or other object
    ndex = 0
    objectStr = ARGV[ndex += 1]
    attempts = ARGV[ndex += 1].to_i
    errCode = ARGV[ndex += 1]
    errMsg = ARGV[ndex += 1]
    
    if errMsg == "successful" then
    	log "Login to #{objectStr} successful"
    elsif attempts > 0 then
      log "Login to #{objectStr} successful after #{attempts} attempts."
    else
    	log "Login to #{objectStr} failed after #{attempts} attempts (error # #{errCode} - #{errMsg})"
    end
  end

  def FatalBackupError
    # A script is hitting its scheduled stop time
    ndex = 0
    scriptName = ARGV[ndex += 1]
    failureCause = ARGV[ndex += 1]
    errCode = ARGV[ndex += 1]
    errMsg = ARGV[ndex += 1]
    errZone = ARGV[ndex += 1]
    
    log "ScriptName #{scriptName} failed with error ##{errCode} - #{errMsg} (#{failureCause})"
  end
  
  # In case Retrospect (or testing) sends an event not listed above
  def method_missing(method_id)
    msg = "Unknown event #{method_id}"
    log msg
  end
end

main
