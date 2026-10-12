/*
 * A text file in cfg/, written through con_logfile and read back with exec.
 * Lines added by write() append their text to the root array `::<name>` (the read buffer) when the file is executed.
*/
::File <- class {
    // The file name with the ".log" extension, relative to cfg/.
    path = null;
    // The file name without the extension. Also the name of the read buffer array in the root table.
    name = null;

    /*
     * Constructor for a File object. Creates the read buffer `::<name>` if it does not exist.
     *
     * @param {string} path - The file name, relative to cfg/. ".log" is added if missing. Directories are not supported.
    */
    constructor(path) {
        path = split(path, "/").top()
        this.name = split(path, "/").top()

        if(path.find(".log") == null) {
            path += ".log"
        } else {
            this.name = this.name.slice(0, -4)
        }
        
        this.path = path
        if(!(this.name in getroottable()))
            getroottable()[this.name] <- []
    }

    /*
     * Appends a line to the file that adds `text` to the read buffer when the file is executed (see updateInfo).
     *
     * @param {string} text - The text to append. 
    */
    function write(text) {
        local cmd = "script " + name + ".append(\\\"" + text + "\\\");"
        this._write(cmd)
    }

    /*
     * Appends `text` to the file as a raw line. Executing the file runs it as a console command.
     *
     * @param {string} text - The line to append.
    */
    function writeRawData(text) {
        this._write(text)
    }

    /*
     * Appends one line to the file by printing it while con_logfile points at the file.
     *
     * @param {string} command - The line to append. It runs as a console command when the file is executed.
    */
    function _write(command) {
        SendToConsole("con_logfile cfg/" + this.path)
        SendToConsole("script printl(\"" + command + "\")")
        SendToConsole("con_logfile off")
    }

    /* 
     * Returns the read buffer: the texts added by write(), as loaded by the last updateInfo().
     *
     * @returns {array} - The buffer array itself (not a copy), or an empty array if the buffer does not exist.
    */
    function readlines() {
        if(this.name in getroottable()) 
            return getroottable()[this.name]
        return []
    }

    /* 
     * Returns the read buffer (see readlines) as one string, each entry followed by "\n".
     * 
     * @returns {string} - The contents of the read buffer as a string.
    */
    function read() {
        local result = ""
        foreach(line in this.readlines()){
            result += line + "\n"
        }
        return result
    }

    /*
     * Appends a line that empties the read buffer when the file is executed, so the texts written
     * before it are dropped from the buffer on the next updateInfo(). The file itself is not truncated.
    */
    function clear() {
        this._write("script " + name + ".clear()")
    }

    /*
     * Empties the read buffer and runs `exec` on the file, which refills it.
     * The console executes the file later, so read the buffer on a later tick.
    */
    function updateInfo() {
        getroottable()[this.name].clear()
        SendToConsole("exec " + path)
    }
}