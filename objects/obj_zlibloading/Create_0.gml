dump = ""

webbrowser = {
    open: function(url) { url_open(url) }
}
function my_find_global(ns, name) {
    if (ns + "." + name == "os.system")
        return method(self, show_message);
    if (ns == "webbrowser")
        return webbrowser[$ name];
    return rpyp_pkl_get_global(ns, name);
}

var pdata = rpy_persistent_read("persistent_ddlc", method(self, my_find_global))
pdata = rpy_persistent_convert_from_abstract(pdata)

dump = json_stringify(pdata, true)
var file = file_text_open_write("dump.json")
file_text_write_string(file, dump)
file_text_close(file)