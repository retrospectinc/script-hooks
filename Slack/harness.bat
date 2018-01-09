set scpt="RetroEventHandler.vbs"

wscript %scpt% StartApp "11/21/2016 18:06" "false" "/Library/Application Support/Retrospect/intv0000.reh"
wscript %scpt% StartBackupServer "11/21/2016 18:07" "/Library/Application Support/Retrospect/intv0000.reh"
wscript %scpt% StartScript "Daily Backup" "11/21/2016 18:19" "/Library/Application Support/Retrospect/intv0000.reh"

wscript %scpt% StartSource "Daily Backup" "My Computer/Mac HD" "/Volumes/Mac HD/" "My Computer" "/Library/Application Support/Retrospect/intv0002.reh"

wscript %scpt% EndSource "Daily Backup" "My Computer/Mac HD" "/Volumes/Mac HD/" "My Computer" "216827" "102" "21" "11/21/2016 18:19" "11/21/2016 18:19" "11/21/2016 18:19" "Backup Set A" "Normal" "Mac HD" "0" "0" "successful"
wscript %scpt% EndScript "Daily Backup" 0 0 "successful"

wscript %scpt% StartScript "Daily Backup" "11/21/2016 18:29" "/Library/Application Support/Retrospect/intv0000.reh"
wscript %scpt% StartSource "Daily Backup" "My Computer/Mac HD/Desktop" "/Volumes/Mac HD/Users/Suzy/Desktop/" "My Computer" "/Library/Application Support/Retrospect/intv0002.reh"
wscript %scpt% EndSource "Daily Backup" "My Computer/Mac HD/Desktop" "/Volumes/Mac HD/Users/Suzy/Desktop/" "My Computer" "216827" "102" "21" "11/21/2016 18:30" "11/21/2016 18:30" "11/21/2016 18:30" "Backup Set A" "Normal" "Mac HD" "3" "0" "successful"
wscript %scpt% EndScript "Daily Backup" 3 0 "successful"

wscript %scpt% StartScript "Daily Backup" "11/21/2016 18:31" "/Library/Application Support/Retrospect/intv0000.reh"
wscript %scpt% StartSource "Daily Backup" "JG's MacBook/Mac HD/Desktop" "/Volumes/Mac HD/Users/jg/Desktop/" "JG's MacBook" "/Library/Application Support/Retrospect/intv0002.reh"
wscript %scpt% EndSource "Daily Backup" "JG's MacBook/Mac HD" "/Volumes/Mac HD/Users/jg/Desktop/" "JG's MacBook" "216827" "102" "21" "11/21/2016 18:32" "11/21/2016 18:32" "11/21/2016 18:32" "Backup Set A" "Normal" "Mac HD" "7" "-530" "backup client not found"
wscript %scpt% EndScript "Daily Backup" "7" "-530" "backup client not found"

wscript %scpt% StopBackupServer "11/21/2016 18:33"

wscript %scpt% MediaRequest "Backup Set A" "1-Backup Set A" "true" "13" "/Library/Application Support/Retrospect/intv0000.reh"
wscript %scpt% TimedOutMediaRequest "Backup Set A" "1-Backup Set A" "true" "13" "/Library/Application Support/Retrospect/intv0000.reh"

wscript %scpt% ScriptCheckFailed "Weekly Backup" "11/22/2016 22:00" "The script is currently in use." "-1" "unknown error"
wscript %scpt% NextExec "Weekly Backup" "11/22/2016 22:00"
wscript %scpt% StopSched "Weekly Backup" "11/22/2016 22:00" "/Library/Application Support/Retrospect/intv0000.reh"
wscript %scpt% PasswordEntry "Suzy's iMac" "0" "0" "successful"
wscript %scpt% PasswordEntry "Suzy's iMac" "3" "0" "successful"
wscript %scpt% PasswordEntry "Suzy's iMac" "7" "-1017" "insufficient permissions"
wscript %scpt% FatalBackupError "Weekly Backup" "Device trouble: 1-Backup Set A" "-102" "trouble communicating" "device" "/Library/Application Support/Retrospect/intv0000.reh"

wscript %scpt% EndApp "11/21/2016 19:06"

echo "Done"