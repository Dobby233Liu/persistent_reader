// Copyright (c) 2022 Liu Wenyuan

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// Portions of this code are based on CPython source code.
// Copyright (c) 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010,
// 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022 Python Software Foundation;
// All Rights Reserved
// See <https://wiki.python.org/moin/PythonSoftwareFoundationLicenseV2Easy> for license.

// Hacked together DDLC persistent reader (protocol 2)
// by Dobby233Liu
// works as long as DDLC don't update to a new Python version

// Copied from cPickle
// Stripped to Protocol 2
// py2 pickler only uses a subset of this so we're safe
global._pickle_opcodes = {
	MARK            : "(",
	STOP            : ".",
	//POP             : "0",
	//POP_MARK        : "1",
	//DUP             : "2",
	//FLOAT           : "F",
	//INT             : "I",
	BININT          : "J",
	BININT1         : "K",
	//LONG            : "L",
	BININT2         : "M",
	NONE            : "N",
	//PERSID          : "P",
	//BINPERSID       : "Q",
	REDUCE          : "R",
	//STRING          : "S",
	//BINSTRING       : "T",
	SHORT_BINSTRING : "U",
	//UNICODE         : "V",
	BINUNICODE      : "X",
	//APPEND          : "a",
	BUILD           : "b",
	GLOBAL          : "c",
	//DICT            : "d",
	EMPTY_DICT      : "}",
	APPENDS         : "e",
	//GET             : "g",
	BINGET          : "h",
	//INST            : "i",
	LONG_BINGET     : "j",
	//LIST            : "l",
	EMPTY_LIST      : "]",
	//OBJ             : "o",
	//PUT             : "p",
	BINPUT          : "q",
	LONG_BINPUT     : "r",
	//SETITEM         : "s",
	//TUPLE           : "t",
	EMPTY_TUPLE     : ")",
	SETITEMS        : "u",
	BINFLOAT        : "G",

	PROTO       : "\x80",
	NEWOBJ      : "\x81",
	//EXT1        : "\x82",
	//EXT2        : "\x83",
	//EXT4        : "\x84",
	TUPLE1      : "\x85",
	TUPLE2      : "\x86",
	TUPLE3      : "\x87",
	NEWTRUE     : "\x88",
	NEWFALSE    : "\x89",
	//LONG1       : "\x8a",
	//LONG4       : "\x8b"
}

function rpyp_pkl_read_binstring(buf, startpoint, len, movecursor = false) {
	if len == 0
		return ""
	else if buffer_get_size(buf) < (startpoint + len)
		throw "String length out of bounds";
	var _buf = buffer_create(len, buffer_fixed, 2)
	buffer_copy(buf, startpoint, len, _buf, 0)
	str = buffer_read(_buf, buffer_string)
	buffer_delete(_buf)
	if movecursor
		buffer_seek(buf, buffer_seek_start, startpoint + len)
	return str
}

function rpyp_pkl_read_line(buf) {
	var startpoint = buffer_tell(buf)
	var endpoint = startpoint
	while (true) {
		if buffer_get_size(buf) <= buffer_tell(buf) {
			throw "Buffer exhausted while reading a line"
		}
		if buffer_read(buf, buffer_u8) == ord("\n") {
			endpoint = buffer_tell(buf) - 1
			break;
		}
	}
	return rpyp_pkl_read_binstring(buf, startpoint, endpoint - startpoint);
}

function _rpyp_pkl__builtin_object() constructor {
	__module__ = "__builtin__"
	__name__ = "object"
	__bases__ = []
	static __new__ = function () {
		// Waiting for a GM bug to be fixed
		/*var args = [];
		for (var i = 0; i < argument_count; i++)
			array_push(args, argument[i]);
		script_execute_ext(__init__, args);*/
		script_execute(__init__);
		return self;
	}
	static __init__ = function () {}
	//static __getattribute__ = function(name) {
	//	return self[$ name]
	//}
	//static __getattr__ = function(name) {
	//	return self[$ name]
	//}
	//static __setattr__ = function(name, value) {
	//	self[$ name] = value
	//}
	//static __delattr__ = function(name) {
	//	self[$ name] = undefined
	//}
	static toString = function() {
		return __module__ + "." + __name__
	}
	//static __str__ = function() {
	//	return string(self)
	//}
	//static __repr__ = function() {
	//	return string(self)
	//}
	static __setstate__ = function (state) {
		var keys = variable_struct_get_names(state);
		for (var i = 0; i < array_length(keys); i++) {
		    self[$ keys[i]] = state[$ keys[i]]
		}
	}
};
function _rpyp_pkl__builtin_tuple() : _rpyp_pkl__builtin_object() constructor {
	__module__ = "__builtin__"
	__name__ = "tuple"
	__bases__ = [_rpyp_pkl__builtin_object]
	__content__ = []
	__brackets_l__ = "("
	__brackets_r__ = ")"
	static __get_content__ = function () {
		return __content__
	}
	static __len__ = function () {
		return array_length(__content__)
	}
	static __getitem__ = function (key) {
		return __content__[key];
	}
	static __setitem__ = function (key, value) {
		__content__[key] = value;
	}
	static __delitem__ = function (key) {
		__content__[key] = undefined;
	}
	static __setstate__ = function (state) {
		__content__ = state
	}
	static toString = function () {
		var str = __brackets_l__ + " ";
		var inside_str = ""
		for (var i = 0; i < array_length(__content__); i++)
			inside_str += string(__content__[i]) + (i == (array_length(__content__) - 1) ? "" : ", ")
		str += inside_str + " " + __brackets_r__
		return str;
	}
};
// bruh
function _rpyp_pkl__builtin_set() : _rpyp_pkl__builtin_tuple() constructor {
	__module__ = "__builtin__"
	__name__ = "set"
	__bases__ = [_rpyp_pkl__builtin_object]
	__brackets_l__ = "set(("
	__brackets_r__ = "))"
	// Waiting for a GM bug to be fixed
	//static __init__ = function() {
	//	for (var i = 0; i < argument_count; i++)
	//		__setitem__(i, argument[i]);
	//}
};
function _rpyp_pkl__builtin_list() : _rpyp_pkl__builtin_tuple() constructor {
	__module__ = "__builtin__"
	__name__ = "list"
	__bases__ = [_rpyp_pkl__builtin_object]
	__brackets_l__ = "["
	__brackets_r__ = "]"
	static extend = function (arr) {
		array_copy(__content__, array_length(__content__), arr, 0, array_length(arr));
	}
};
function _rpyp_pkl__builtin_dict() : _rpyp_pkl__builtin_object() constructor {
	__module__ = "__builtin__"
	__name__ = "dict"
	__bases__ = [_rpyp_pkl__builtin_object]
	__content__ = {}
	__brackets_l__ = "{"
	__brackets_r__ = "}"
	static __get_content__ = function () {
		return __content__
	}
	static __getitem__ = function (key) {
		return __content__[$ key];
	}
	static __setitem__ = function (key, value) {
		__content__[$ key] = value;
	}
	static __delitem__ = function (key) {
		__content__[$ key] = undefined;
	}
	static __len__ = function () {
		return array_length(variable_struct_get_names(state));
	}
	static toString = function () {
		return string(__content__);
	}
	static __setstate__ = function (state) {
		var keys = variable_struct_get_names(state);
		for (var i = 0; i < array_length(keys); i++) {
		    __content__[$ keys[i]] = state[$ keys[i]]
		}
	}
};
function _rpyp_pkl_renpy_persistent_Persistent() : _rpyp_pkl__builtin_object() constructor {
	__module__ = "renpy.persistent"
	__name__ = "Persistent"
	__bases__ = [_rpyp_pkl__builtin_object]
};
function _rpyp_pkl_renpy_preferences_Preferences() : _rpyp_pkl__builtin_object() constructor {
	__module__ = "renpy.preferences"
	__name__ = "Preferences"
	__bases__ = [_rpyp_pkl__builtin_object]
};
function _rpyp_pkl_renpy_python_RevertableDict() : _rpyp_pkl__builtin_dict() constructor {
	__module__ = "renpy.python"
	__name__ = "RevertableDict"
	__bases__ = [_rpyp_pkl__builtin_dict, _rpyp_pkl__builtin_object]
};
function _rpyp_pkl_renpy_python_RevertableList() : _rpyp_pkl__builtin_list() constructor {
	__module__ = "renpy.python"
	__name__ = "RevertableList"
	__bases__ = [_rpyp_pkl__builtin_list, _rpyp_pkl__builtin_object]
};
function _rpyp_pkl_renpy_python_RevertableSet() : _rpyp_pkl__builtin_set() constructor {
	__module__ = "renpy.python"
	__name__ = "RevertableSet"
	__bases__ = [_rpyp_pkl__builtin_set, _rpyp_pkl__builtin_object]
};

function rpyp_pkl_get_class(class, name) {
	switch (class + "." + name) {
		case "__builtin__.object":
			return _rpyp_pkl__builtin_object;
			break;
		case "__builtin__.tuple":
			return _rpyp_pkl__builtin_tuple;
			break;
		case "__builtin__.dict":
			return _rpyp_pkl__builtin_dict;
			break;
		case "__builtin__.set":
			return _rpyp_pkl__builtin_set;
			break;
		case "__builtin__.list":
			return _rpyp_pkl__builtin_list;
			break;
		case "renpy.persistent.Persistent":
			return _rpyp_pkl_renpy_persistent_Persistent;
			break;
		case "renpy.python.RevertableDict":
			return _rpyp_pkl_renpy_python_RevertableDict;
			break;
		case "renpy.python.RevertableList":
			return _rpyp_pkl_renpy_python_RevertableList;
			break;
		case "renpy.python.RevertableSet":
			return _rpyp_pkl_renpy_python_RevertableSet;
			break;
		case "renpy.preferences.Preferences":
			return _rpyp_pkl_renpy_preferences_Preferences;
			break;
		default:
			throw "Unknown class " + class + "." + name;
			break;
	}
}
function rpyp_pkl_fakeclass_new(class, args) {
	// Waiting for a GM bug to be fixed
	// return script_execute_ext(new class().__new__, args);
	return new class().__new__();
}
function rpyp_pkl_pop_mark(metastack) {
	var res = metastack[array_length(metastack) - 1]
	array_pop(metastack)
	return res
}

function rpy_persistent_read_raw_buffer(buf) {
	var pkl_version = 0;
	var memo = []
	var stack = []
	var metastack = []
	var correctly_stopped = false;
	var value = undefined;
	if buffer_get_size(buf) <= 0
		throw "Buffer is empty";
	try {
		while (buffer_get_size(buf) > buffer_tell(buf)) {
			var inst = buffer_read(buf, buffer_u8)
			var inst_str = chr(inst)
			switch inst_str {
				case global._pickle_opcodes.PROTO:
					pkl_version = buffer_read(buf, buffer_u8)
					if (pkl_version > 2)
						throw "Unsupported pickle protocol version " + string(pkl_version);
					break;
				case global._pickle_opcodes.GLOBAL:
					var origin = rpyp_pkl_read_line(buf)
					var class = rpyp_pkl_read_line(buf)
					array_push(stack, rpyp_pkl_get_class(origin, class))
					break;
				case global._pickle_opcodes.BINPUT:
					var loc = buffer_read(buf, buffer_u8)
					if (loc < 0)
						throw "Negative BINPUT argument";
					array_set(memo, loc, stack[array_length(stack) - 1])
					break;
				case global._pickle_opcodes.EMPTY_TUPLE:
					array_push(stack, rpyp_pkl_fakeclass_new(rpyp_pkl_get_class("__builtin__", "tuple"), []))
					break;
				case global._pickle_opcodes.NEWOBJ:
					var cls = stack[array_length(stack) - 2]
					var args = stack[array_length(stack) - 1].__get_content__()
					array_pop(stack)
					array_pop(stack)
					array_push(stack, rpyp_pkl_fakeclass_new(cls, args))
					break;
				case global._pickle_opcodes.EMPTY_DICT:
					array_push(stack, rpyp_pkl_fakeclass_new(rpyp_pkl_get_class("__builtin__", "dict"), []))
					break;
				case global._pickle_opcodes.MARK:
					array_push(metastack, stack)
					stack = []
					break;
				case global._pickle_opcodes.SHORT_BINSTRING:
					var len = buffer_read(buf, buffer_u8);
					var str = rpyp_pkl_read_binstring(buf, buffer_tell(buf), len, true);
					array_push(stack, str)
					break;
				case global._pickle_opcodes.BININT1:
					array_push(stack, buffer_read(buf, buffer_u8))
					break;
				case global._pickle_opcodes.EMPTY_LIST:
					array_push(stack, rpyp_pkl_fakeclass_new(rpyp_pkl_get_class("__builtin__", "list"), []))
					break;
				case global._pickle_opcodes.BINUNICODE:
					var len = buffer_read(buf, buffer_s32);
					var str = rpyp_pkl_read_binstring(buf, buffer_tell(buf), len, true);
					array_push(stack, str)
					break;
				case global._pickle_opcodes.LONG_BINPUT:
					var loc = buffer_read(buf, buffer_u32)
					if (loc < 0)
						throw "Negative LONG_BINPUT argument";
					array_set(memo, loc, stack[array_length(stack) - 1])
					break;
				case global._pickle_opcodes.APPENDS:
					var contents = stack
					stack = rpyp_pkl_pop_mark(metastack);
					stack[array_length(stack) - 1].extend(contents);
					break;
				case global._pickle_opcodes.TUPLE1:
					// Waiting for a GM bug to be fixed to just supply content as second arg
					var obj = rpyp_pkl_fakeclass_new(rpyp_pkl_get_class("__builtin__", "tuple"), []);
					obj.__content__ = [stack[array_length(stack) - 1]]
					array_pop(stack)
					array_push(stack, obj)
					break;
				case global._pickle_opcodes.REDUCE:
					// i'm being lazy here
					var callable = stack[array_length(stack) - 1];
					array_pop(stack)
					var args = stack[array_length(stack) - 1];
					array_pop(stack)
					// master hax
					//array_push(rpyp_pkl_fakeclass_new(callable, args.__content__))
					var newobj = callable.__new__()
					for (var i = 0; i < array_length(args); i++)
						newobj.__setitem__(i, args[i]);
					array_push(stack, newobj)
					break;
				case global._pickle_opcodes.NEWTRUE:
					array_push(stack, true)
					break;
				case global._pickle_opcodes.NEWFALSE:
					array_push(stack, false)
					break;
				case global._pickle_opcodes.BININT:
					array_push(stack, buffer_read(buf, buffer_s32))
					break;
				case global._pickle_opcodes.BININT2:
					array_push(stack, buffer_read(buf, buffer_u16))
					break;
				case global._pickle_opcodes.TUPLE2:
					// Waiting for a GM bug to be fixed to just supply content as second arg
					var obj = rpyp_pkl_fakeclass_new(rpyp_pkl_get_class("__builtin__", "tuple"), []);
					obj.__content__ = [stack[array_length(stack) - 1], stack[array_length(stack) - 2]]
					array_pop(stack)
					array_pop(stack)
					array_push(stack, obj)
					break;
				case global._pickle_opcodes.TUPLE3:
					// Waiting for a GM bug to be fixed to just supply content as second arg
					var obj = rpyp_pkl_fakeclass_new(rpyp_pkl_get_class("__builtin__", "tuple"), []);
					obj.__content__ = [stack[array_length(stack) - 1], stack[array_length(stack) - 2], stack[array_length(stack) - 3]]
					array_pop(stack)
					array_pop(stack)
					array_pop(stack)
					array_push(stack, obj)
					break;
				case global._pickle_opcodes.LONG_BINGET:
					var index = buffer_read(buf, buffer_u32)
					array_push(stack, memo[index])
					break;
				case global._pickle_opcodes.SETITEMS:
					var contents = stack
					stack = rpyp_pkl_pop_mark(metastack);
					var dict = stack[array_length(stack) - 1]
					for (var i = 0; i < array_length(contents); i += 2)
						dict.__setitem__(contents[i], contents[i + 1])
					break;
				case global._pickle_opcodes.NONE:
					array_push(stack, undefined);
					break;
				case global._pickle_opcodes.BUILD:
					var state = stack[array_length(stack) - 1];
					array_pop(stack)
					var obj = stack[array_length(stack) - 1];
					obj.__setstate__(state.__content__)
					break;
				case global._pickle_opcodes.BINGET:
					var index = buffer_read(buf, buffer_u8)
					array_push(stack, memo[index])
					break;
				case global._pickle_opcodes.BINFLOAT:
					array_push(stack, buffer_read(buf, buffer_f64))
					break;
				case global._pickle_opcodes.STOP:
					var value = stack[array_length(stack) - 1];
					array_pop(stack)
					throw "STOP"
					break;
				default:
					throw "Unknown opcode " + string(inst);
					break;
			}
		}
	} catch (_e) {
		if is_string(_e) {
			if _e == "STOP" {
				correctly_stopped = true
			} else {
				_e += "\nBuffer read to position " + string(buffer_tell(buf))
				throw _e
			}
		} else {
			throw (_e.message + "\nBuffer read to position " + string(buffer_tell(buf)))
		}
	}
	if !correctly_stopped {
		throw "EOF reached while reading buffer, however STOP opcode is not called"
	}
	return value;
}
function rpy_persistent_read_buffer(cmp_buff) {
	var pickle_buff = buffer_decompress(cmp_buff)
	var ret = rpy_persistent_read_raw_buffer(pickle_buff)
	buffer_delete(pickle_buff)
	return ret
}
function rpy_persistent_read(fn){
	var orig_file = buffer_load(fn);
	if !buffer_exists(orig_file)
		show_error("Can't load file " + fn, true)
	var ret = rpy_persistent_read_buffer(orig_file)
	buffer_delete(orig_file)
	return ret
}
