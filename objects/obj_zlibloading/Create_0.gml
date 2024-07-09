var pdataa = rpy_persistent_read("persistent_rival")
pdata = rpy_persistent_convert_from_abstract(pdataa)

dump = json_stringify(pdata, true)
var file = file_text_open_write("dump.json")
/*var keys = variable_struct_get_names(pdata);
for (var i = 0; i < array_length(keys); i++) {
	dump += keys[i] + " = " + string(pdata[$ keys[i]]) + "\n"
}*/
file_text_write_string(file, dump)
file_text_close(file)
