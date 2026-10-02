IncludeScript("PCapture-Lib/SRC/PCapture-Lib")

::LibLogger <- LoggerLevels.Off

::RunTests <- function(testName, tests_table) {
    macros.fprint("\n{} tests are running...", testName)
    printl("-------------------------------------------------")
    
    local passed_tests = tests_table.len()
    local unsuccessful = List()
    foreach(name, test_func in tests_table) {
        try {
            test_func()
        } catch(exception) {
            macros.fprint("{} test error: function {} ({})", testName, name, exception)
            unsuccessful.append(name)
            passed_tests--
        }
    }

    local resTest = "Tests passed successfully!"
    if(unsuccessful.len() > 0) {
        resTest = macros.format("{} tests with error:\n* {}", testName, unsuccessful.join("\n* "))
        printl("")
    } 
    macros.fprint("~~ {} tests result: {}/{} passed. ~~", testName, passed_tests, tests_table.len())
    printl(resTest)
    printl("-------------------------------------------------\n")
}

function RunAllTests() {
    printl("\n~~~~~~~~~~~~~~~~~~~~~~~~~\nRUN ALL TESTS\n~~~~~~~~~~~~~~~~~~~~~~~~~")
    IncludeScript("PCapture-LIB/Tests/Math")
    IncludeScript("PCapture-LIB/Tests/IDT")
    IncludeScript("PCapture-LIB/Tests/Utils")
    IncludeScript("PCapture-LIB/Tests/ActionScheduler")
    IncludeScript("PCapture-LIB/Tests/ScriptEvents")
    IncludeScript("PCapture-LIB/Tests/TracePlus")
    IncludeScript("PCapture-LIB/Tests/PhysControl")
}

if(getstackinfos(2) == null) {
    RunAllTests()
}