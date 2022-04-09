pdataa = rpy_persistent_read("persistent")
pdata = rpy_persistent_convert_from_abstract(pdataa)
dump = ""
var file = file_text_open_write("dump.txt")
var keys = variable_struct_get_names(pdata);
for (var i = 0; i < array_length(keys); i++) {
	dump += keys[i] + " = " + string(pdata[$ keys[i]]) + "\n"
}
file_text_write_string(file, dump)
file_text_close(file)
