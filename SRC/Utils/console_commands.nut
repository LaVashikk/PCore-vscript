commands_separator <- ",\n"

// Basic information
macros.CreateCommand("PCore_ver", "script printl(::LIB_VERSION)")

// Logger level control commands
if(developer() > 0) {
	macros.CreateCommand("PCore_level_trace", "script ::LibLogger = LoggerLevels.Trace")
	macros.CreateCommand("PCore_log_debug", "script ::LibLogger = LoggerLevels.Debug")
	macros.CreateCommand("PCore_log_info", "script ::LibLogger = LoggerLevels.Info")
}
macros.CreateCommand("PCore_log_off", "script ::LibLogger = LoggerLevels.Off")

// Schedule event control commands
macros.CreateCommand("PCore_schedule_list", "script try { printl(macros.GetKeys(ScheduleEvent.eventsList).join(commands_separator)) } catch(_) {}")
macros.CreateCommand("PCore_schedule_clear", "script ScheduleEvent.CancelAll()")

// Information dump commands
macros.CreateCommand("PCore_vs_events", "script try { printl(macros.GetKeys(::AllScriptEvents).join(commands_separator)) } catch(_) {}")
macros.CreateCommand("PCore_players", "script try { printl(AllPlayers.join(commands_separator)) } catch(_) {}")
