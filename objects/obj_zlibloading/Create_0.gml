dump = ""

var pdata = rpy_persistent_read("persistent_rsj")
pdata = rpy_persistent_convert_from_abstract(pdata)

dump = json_stringify(pdata, true)
var file = file_text_open_write("dump.json")
file_text_write_string(file, dump)
file_text_close(file)

/*var yy = new _rpyp_pkl_renpy_python_RevertableDict().__new__([])
show_message(rpyp_pkl_fakeclass_isinstance(yy, "renpy.python", "RevertableDict"))*/