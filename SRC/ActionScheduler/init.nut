/*+--------------------------------------------------------------------------------+
|                           PCapture Vscripts Library                              |
+----------------------------------------------------------------------------------+
| Author:                                                                          |
|     Event Orchestrator - laVashik ・人・                                          |
+----------------------------------------------------------------------------------+
|   The Events module, offering an advanced event scheduling and management system | 
|   for creating complex, timed events with precision and control.                 |
+----------------------------------------------------------------------------------+ */ 


::ScheduleEvent <- {
    // Event name -> List of pending ScheduleAction objects, sorted by execution time. "global" always exists.
    eventsList = {global = List()},
    
    Add = null,
    AddActions = null,
    AddInterval = null,

    Cancel = null,
    CancelAll = null,
    
    GetEvent = null,
    
    IsValid = null,
}

IncludeScript("PCapture-LIB/SRC/ActionScheduler/action")
IncludeScript("PCapture-LIB/SRC/ActionScheduler/action_scheduler")
IncludeScript("PCapture-LIB/SRC/ActionScheduler/event_handler")

// A logic_timer runs ScheduledEventLoop every tick.
if(!Entities.FindByName(null, "@ScheduledEventLoop")) {
    local timer = entLib.CreateByClassname("logic_timer", {RefireTime=0.001, targetname="@ScheduledEventLoop"})
    timer.ConnectOutput("OnTimer", "ScheduledEventLoop")
    EntFire("@ScheduledEventLoop", "Enable")
}