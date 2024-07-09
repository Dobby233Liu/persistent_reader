// Copyright (c) 2022-2024 Liu Wenyuan

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
// Stripped to Protocol 2, includes subset of opcodes from later protocols
global._pickle_opcodes = {
	MARK            : ord("("),
	STOP            : ord("."),
	POP             : ord("0"),
	POP_MARK        : ord("1"),
	DUP             : ord("2"),
	FLOAT           : ord("F"),
	INT             : ord("I"),
	BININT          : ord("J"),
	BININT1         : ord("K"),
	LONG            : ord("L"),
	BININT2         : ord("M"),
	NONE            : ord("N"),
	PERSID          : ord("P"),
	BINPERSID       : ord("Q"),
	REDUCE          : ord("R"),
	STRING          : ord("S"),
	BINSTRING       : ord("T"),
	SHORT_BINSTRING : ord("U"),
	UNICODE         : ord("V"),
	BINUNICODE      : ord("X"),
	APPEND          : ord("a"),
	BUILD           : ord("b"),
	GLOBAL          : ord("c"),
	DICT            : ord("d"),
	EMPTY_DICT      : ord("}"),
	APPENDS         : ord("e"),
	GET             : ord("g"),
	BINGET          : ord("h"),
	INST            : ord("i"),
	LONG_BINGET     : ord("j"),
	LIST            : ord("l"),
	EMPTY_LIST      : ord("]"),
	OBJ             : ord("o"),
	PUT             : ord("p"),
	BINPUT          : ord("q"),
	LONG_BINPUT     : ord("r"),
	SETITEM         : ord("s"),
	TUPLE           : ord("t"),
	EMPTY_TUPLE     : ord(")"),
	SETITEMS        : ord("u"),
	BINFLOAT        : ord("G"),

	// Protocol 2
	PROTO       : ord("\x80"),
	NEWOBJ      : ord("\x81"),
	EXT1        : ord("\x82"),
	EXT2        : ord("\x83"),
	EXT4        : ord("\x84"),
	TUPLE1      : ord("\x85"),
	TUPLE2      : ord("\x86"),
	TUPLE3      : ord("\x87"),
	NEWTRUE     : ord("\x88"),
	NEWFALSE    : ord("\x89"),
	LONG1       : ord("\x8a"),
	LONG4       : ord("\x8b"),

	// Protocol 3
	BINBYTES       : ord("B"),
	SHORT_BINBYTES : ord("C"),

	// Protocol 4
	// 8-bytes not supported by GM rn
	SHORT_BINUNICODE : ord("\x8c"),
	BINUNICODE8      : ord("\x8d"),
	BINBYTES8        : ord("\x8e"),
	EMPTY_SET        : ord("\x8f"),
	ADDITEMS         : ord("\x90"),
	FROZENSET        : ord("\x91"),
	NEWOBJ_EX        : ord("\x92"),
	STACK_GLOBAL     : ord("\x93"),
	MEMOIZE          : ord("\x94"),
	FRAME            : ord("\x95"),

	// Protocol 5
	BYTEARRAY8       : ord("\x96"),
	NEXT_BUFFER      : ord("\x97"),
	READONLY_BUFFER  : ord("\x98"),
}

#macro _RPYP_PKL_POP_MARK array_pop(metastack)
#macro _RPYP_PKL_POP_MARK_CONTENTS var contents = stack; stack = _RPYP_PKL_POP_MARK
#macro _RPYP_PKL_STOP_CODE 0xffffffff

// Based on https://meseta.itch.io/gm-msgpack
function rpyp_pkl_read_double_be(buf) {
    var fend;
    var scratch = buffer_create(8, buffer_fixed, 1);
    try {
        buffer_poke(scratch, 7, buffer_u8, buffer_read(buf, buffer_u8));
        buffer_poke(scratch, 6, buffer_u8, buffer_read(buf, buffer_u8));
        buffer_poke(scratch, 5, buffer_u8, buffer_read(buf, buffer_u8));
        buffer_poke(scratch, 4, buffer_u8, buffer_read(buf, buffer_u8));
        buffer_poke(scratch, 3, buffer_u8, buffer_read(buf, buffer_u8));
        buffer_poke(scratch, 2, buffer_u8, buffer_read(buf, buffer_u8));
        buffer_poke(scratch, 1, buffer_u8, buffer_read(buf, buffer_u8));
        buffer_poke(scratch, 0, buffer_u8, buffer_read(buf, buffer_u8));
        fend = buffer_read(scratch, buffer_f64);
    } finally {
        buffer_delete(scratch);
    }
    return fend;
}

// escaped strings parsing is currently not supported
function rpyp_pkl_read_binstring(buf, startpoint, len, movecursor = true, escape = false) {
	if len == 0
		return ""
	else if buffer_get_size(buf) < (startpoint + len)
		throw "String length out of bounds";
	var _buf = buffer_create(len, buffer_fixed, 1)
	buffer_copy(buf, startpoint, len, _buf, 0)
	var str = buffer_read(_buf, buffer_text)
	buffer_delete(_buf)
	if movecursor
		buffer_seek(buf, buffer_seek_start, startpoint + len)
	return str
}
function rpyp_pkl_read_line(buf, escape = false) {
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
	return rpyp_pkl_read_binstring(buf, startpoint, endpoint - startpoint, false, escape);
}

/**
* @returns {Real|Bool}
*/
function rpyp_pkl_from_decl(str, short = false) {
	if string_length(str) <= 0
		throw "Decimal long string too short"
	if string_char_at(str, string_length(str)) == "L"
		str = string_copy(str, 0, string_length(str) - 1)
	if short {
		if str == "00"
			return false
		else if str == "01"
			return true
	}
	// evil
	return round(real(str))
}

function _rpyp_pkl__builtin_object() constructor {
	__module__ = "__builtin__"
	__name__ = "object"
	__bases__ = []
    __pass_raw_args__ = false
    __init__ = function (_, __) {}
    static __empty_kwargs__ = {}
	__new__ = function (args, kwargs=__empty_kwargs__ /* fixme */) {
        if (__pass_raw_args__)
            __init__(args, kwargs)
        else
		    script_execute_ext(__init__, args);
		return self;
	}
	static toString = function() {
		return __module__ + "." + __name__
	}
	__setstate__ = function (state) {
		var keys = variable_struct_get_names(state);
		for (var i = 0; i < array_length(keys); i++) {
		    self[$ keys[i]] = state[$ keys[i]]
		}
		return self;
	}
};
function _rpyp_pkl__builtin_tuple() : _rpyp_pkl__builtin_object() constructor {
	__module__ = "__builtin__"
	__name__ = "tuple"
	__bases__ = [_rpyp_pkl__builtin_object]
	__content__ = []
	__brackets_l__ = "("
	__brackets_r__ = ")"
    __pass_raw_args__ = true
	__init__ = function(args) {
        __content__ = variable_clone(args, 1)
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
		delete __content__[key];
	}
	__setstate__ = undefined
	static toString = function () {
		return __brackets_l__ + string(__content__) + __brackets_r__;
	}
};
// bruh
function _rpyp_pkl__builtin_set() : _rpyp_pkl__builtin_tuple() constructor {
	__module__ = "__builtin__"
	__name__ = "set"
	__bases__ = [_rpyp_pkl__builtin_object]
	__brackets_l__ = "set(("
	__brackets_r__ = "))"
	static add = function(value) {
		array_push(__content__, value)
	}
	__setstate__ = function (state) {
        __content__ = array_concat(__content__, state)
	}
};
function _rpyp_pkl__builtin_frozenset() : _rpyp_pkl__builtin_set() constructor {
	__module__ = "__builtin__"
	__name__ = "frozenset"
	__bases__ = [_rpyp_pkl__builtin_set, _rpyp_pkl__builtin_object]
	__brackets_l__ = "frozenset({"
	__brackets_r__ = "})"
	static add = function(value) {
		throw "Modification disallowed"
	}
	static __getitem__ = function (key) {
		throw "Modification disallowed"
	}
	static __setitem__ = function (key, value) {
		throw "Modification disallowed"
	}
	static __delitem__ = function (key) {
		throw "Modification disallowed"
	}
};
function _rpyp_pkl__builtin_list() : _rpyp_pkl__builtin_tuple() constructor {
	__module__ = "__builtin__"
	__name__ = "list"
	__bases__ = [_rpyp_pkl__builtin_object]
	__brackets_l__ = "["
	__brackets_r__ = "]"
	static extend = function (arr) {
		__content__ = array_concat(__content__, arr)
		return self;
	}
};
function _rpyp_pkl__builtin_dict() : _rpyp_pkl__builtin_object() constructor {
	__module__ = "__builtin__"
	__name__ = "dict"
	__bases__ = [_rpyp_pkl__builtin_object]
	__content__ = {}
	__brackets_l__ = "{"
	__brackets_r__ = "}"
	__dict__ = self
	__init__ = function() {
		if argument_count > 0 {
			throw "Unimplemented";
		}
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
// this needs to be done for some reason
function _rpyp_pkl_renpy_python_RevertableSet() : _rpyp_pkl__builtin_tuple() constructor {
	__module__ = "renpy.python"
	__name__ = "RevertableSet"
	__bases__ = [_rpyp_pkl__builtin_set, _rpyp_pkl__builtin_object]
	__brackets_l__ = "set(("
	__brackets_r__ = "))"
	static add = function(value) {
		array_push(__content__, value)
	}
	__setstate__ = function (state) {
        __content__ = array_concat(__content__, state)
	}
};

function rpyp_pkl_get_class(class, name) {
    static class_lut = {
    	"__builtin__.object" : _rpyp_pkl__builtin_object,
    	"__builtin__.tuple" : _rpyp_pkl__builtin_tuple,
    	"__builtin__.dict" : _rpyp_pkl__builtin_dict,
    	"__builtin__.set" : _rpyp_pkl__builtin_set,
    	"__builtin__.frozenset" : _rpyp_pkl__builtin_frozenset,
    	"__builtin__.list" : _rpyp_pkl__builtin_list,
    	"renpy.persistent.Persistent" : _rpyp_pkl_renpy_persistent_Persistent,
    	"renpy.python.RevertableDict" : _rpyp_pkl_renpy_python_RevertableDict,
    	"renpy.python.RevertableList" : _rpyp_pkl_renpy_python_RevertableList,
    	"renpy.python.RevertableSet" : _rpyp_pkl_renpy_python_RevertableSet,
    	"renpy.preferences.Preferences" : _rpyp_pkl_renpy_preferences_Preferences
    }

    var class_namex = class + "." + name;
    var class_ctor = class_lut[$ class_namex]
    if (class_ctor == undefined)
    	throw "Unknown class " + class_namex;
    return class_ctor;
}

function rpyp_pkl_fakeclass_isinstance(inst, module, name) {
	return is_struct(inst) && inst.__module__ == module && inst.__name__ == name
}

function rpyp_pkl_callfunc(callable, args) {
	if is_method(callable) {
		if is_struct(args) {
			if args.__content__ == undefined
				throw "Class is not an array-like fake Python class"
			args = args.__content__
		}
        if !is_array(args) {
			throw "args argument is not an array"
		}
		return script_execute_ext(callable, args)
	} else {
		throw "Object is not callable"
	}
}

function _rpyp_pkl_interpreter(_buf, _find_class) constructor {
    buf = _buf
    find_class = _find_class
    version = -1
	memo = []
	stack = []
	metastack = []
    value = undefined
	static inst_lut = []
	inst_lut[global._pickle_opcodes.PROTO] = function PROTO () {
		version = buffer_read(buf, buffer_u8)
		if (version > 2)
			throw "Pickle protocol version " + string(pkl_version) + " is not fully supported. For safety reading is terminated.";
	};
	inst_lut[global._pickle_opcodes.GLOBAL] = function GLOBAL () {
		var origin = rpyp_pkl_read_line(buf)
		var class = rpyp_pkl_read_line(buf)
		class = method(self, find_class(origin, class))
		array_push(stack, class)
	};
	inst_lut[global._pickle_opcodes.STACK_GLOBAL] = function STACK_GLOBAL () {
		var class = array_pop(stack)
		var origin = array_pop(stack)
		array_push(stack, find_class(origin, class))
	};
	inst_lut[global._pickle_opcodes.BINPUT] = function BINPUT () {
		var loc = buffer_read(buf, buffer_u8)
		if (loc < 0)
			throw "Negative BINPUT argument";
		memo[loc] = array_last(stack)
	};
	inst_lut[global._pickle_opcodes.EMPTY_TUPLE] = function EMPTY_TUPLE () {
		array_push(stack, new _rpyp_pkl__builtin_tuple().__new__([]))
	};
	inst_lut[global._pickle_opcodes.NEWOBJ] = function NEWOBJ () {
		var args = array_pop(stack).__content__
		var cls = array_pop(stack)
		array_push(stack, new cls().__new__(args))
	};
	inst_lut[global._pickle_opcodes.EMPTY_DICT] = function EMPTY_DICT () {
		array_push(stack, new _rpyp_pkl__builtin_dict().__new__([]))
	};
	inst_lut[global._pickle_opcodes.EMPTY_SET] = function EMPTY_SET () {
		array_push(stack, new _rpyp_pkl__builtin_set().__new__([]))
	};
	inst_lut[global._pickle_opcodes.MARK] = function MARK () {
		array_push(metastack, stack)
		stack = []
	};
	inst_lut[global._pickle_opcodes.BINSTRING] = function BINSTRING () {
		var len = buffer_read(buf, buffer_s32);
		var str = rpyp_pkl_read_binstring(buf, buffer_tell(buf), len, true);
		array_push(stack, str)
	};
	inst_lut[global._pickle_opcodes.SHORT_BINSTRING] = function SHORT_BINSTRING () {
		var len = buffer_read(buf, buffer_u8);
		var str = rpyp_pkl_read_binstring(buf, buffer_tell(buf), len, true);
		array_push(stack, str)
	};
	inst_lut[global._pickle_opcodes.BININT1] = function BININT1 () {
		array_push(stack, buffer_read(buf, buffer_u8))
	};
	inst_lut[global._pickle_opcodes.EMPTY_LIST] = function EMPTY_LIST () {
		array_push(stack, new _rpyp_pkl__builtin_list().__new__([]))
	};
	inst_lut[global._pickle_opcodes.BINUNICODE] = function BINUNICODE () {
		var len = buffer_read(buf, buffer_u32);
		var str = rpyp_pkl_read_binstring(buf, buffer_tell(buf), len, true);
		array_push(stack, str)
	};
	inst_lut[global._pickle_opcodes.SHORT_BINUNICODE] = function SHORT_BINUNICODE () {
		var len = buffer_read(buf, buffer_u8);
		var str = rpyp_pkl_read_binstring(buf, buffer_tell(buf), len, true);
		array_push(stack, str)
	};
	inst_lut[global._pickle_opcodes.LONG_BINPUT] = function LONG_BINPUT () {
		var loc = buffer_read(buf, buffer_u32)
		if (loc < 0)
			throw "Negative LONG_BINPUT argument";
		memo[loc] = array_last(stack)
	};
	inst_lut[global._pickle_opcodes.APPENDS] = function APPENDS () {
		_RPYP_PKL_POP_MARK_CONTENTS;
		var list = array_last(stack);
		list.__content__ = array_concat(list.__content__, contents);
	};
	inst_lut[global._pickle_opcodes.TUPLE1] = function TUPLE1 () {
		var obj = new _rpyp_pkl__builtin_tuple().__new__([array_pop(stack)]);
		array_push(stack, obj)
	};
	inst_lut[global._pickle_opcodes.REDUCE] = function REDUCE () {
		var args = array_pop(stack);
		var callable = array_pop(stack);
		array_push(stack, rpyp_pkl_callfunc(callable, args))
	};
	inst_lut[global._pickle_opcodes.NEWTRUE] = function NEWTRUE () {
		array_push(stack, true)
	};
	inst_lut[global._pickle_opcodes.NEWFALSE] = function NEWFALSE () {
		array_push(stack, false)
	};
	inst_lut[global._pickle_opcodes.BININT] = function BININT () {
		array_push(stack, buffer_read(buf, buffer_s32))
	};
	inst_lut[global._pickle_opcodes.BININT2] = function BININT2 () {
		array_push(stack, buffer_read(buf, buffer_u16))
	};
	inst_lut[global._pickle_opcodes.TUPLE2] = function TUPLE2 () {
		var tcontents = []
		tcontents[1] = array_pop(stack)
		tcontents[0] = array_pop(stack)
		var obj = new _rpyp_pkl__builtin_tuple().__new__(tcontents);
		array_push(stack, obj)
	};
	inst_lut[global._pickle_opcodes.TUPLE3] = function TUPLE3 () {
		var tcontents = []
		tcontents[2] = array_pop(stack)
		tcontents[1] = array_pop(stack)
		tcontents[0] = array_pop(stack)
		var obj = new _rpyp_pkl__builtin_tuple().__new__(tcontents);
		array_push(stack, obj)
	};
	inst_lut[global._pickle_opcodes.LONG_BINGET] = function LONG_BINGET () {
		var index = buffer_read(buf, buffer_u32)
		array_push(stack, memo[index])
	};
	inst_lut[global._pickle_opcodes.SETITEMS] = function SETITEMS () {
		_RPYP_PKL_POP_MARK_CONTENTS;
		var dict = array_last(stack)
        var contentsl = array_length(contents)
		for (var i = 0; i < contentsl; i += 2)
			dict.__content__[$ contents[i]] = contents[i + 1]
	};
	inst_lut[global._pickle_opcodes.ADDITEMS] = function ADDITEMS () {
		_RPYP_PKL_POP_MARK_CONTENTS;
		array_last(stack).__content__ = contents
	};
	inst_lut[global._pickle_opcodes.NONE] = function NONE () {
		array_push(stack, undefined);
	};
	inst_lut[global._pickle_opcodes.BUILD] = function BUILD () {
		var state = array_pop(stack);
		var obj = array_last(stack);
		if obj.__setstate__ != undefined {
			stack[array_length(stack) - 1] = obj.__setstate__(state.__content__)
		} else {
			// FIXME: what
			var slotstate = undefined;
			if rpyp_pkl_fakeclass_isinstance(state, "__builtin__", "tuple") && state.__len__() == 2 {
				slotstate = state.__content__[1]
				state = state.__content__[0]
			}
			if state != undefined {
				var rstate = state.__content__
				var sitems = variable_struct_get_names(rstate)
				for (var i = 0; i < array_length(sitems); i++) {
					obj.__dict__.__content__[$ sitems[i]] = rstate[$ sitems[i]]
				}
			}
			if slotstate != undefined {
				var rslotstate = slotstate.__content__
				var ssitems = variable_struct_get_names(rslotstate)
				for (var i = 0; i < array_length(ssitems); i++) {
					obj[$ ssitems[i]] = rslotstate[$ ssitems[i]]
				}
			}
		}
	};
	inst_lut[global._pickle_opcodes.BINGET] = function BINGET () {
		var index = buffer_read(buf, buffer_u8)
		array_push(stack, memo[index])
	};
	inst_lut[global._pickle_opcodes.BINFLOAT] = function BINFLOAT () {
		array_push(stack, rpyp_pkl_read_double_be(buf))
	};
	inst_lut[global._pickle_opcodes.STOP] = function STOP () {
		value = array_pop(stack);
		throw _RPYP_PKL_STOP_CODE
	};
    function ext_stub () {
		throw "Extensions are not supported. Corrupt persistent file?"
	};
	inst_lut[global._pickle_opcodes.EXT1] = ext_stub
	inst_lut[global._pickle_opcodes.EXT2] = ext_stub
	inst_lut[global._pickle_opcodes.EXT4] = ext_stub
    function long_stub () {
		throw "Long numbers are currently not supported. Corrupt persistent file?"
	};
	inst_lut[global._pickle_opcodes.LONG] = long_stub
	inst_lut[global._pickle_opcodes.LONG1] = long_stub
	inst_lut[global._pickle_opcodes.LONG4] = long_stub
	inst_lut[global._pickle_opcodes.POP] = function POP () {
		if array_pop(stack) == undefined
			stack = _RPYP_PKL_POP_MARK
	};
	inst_lut[global._pickle_opcodes.POP_MARK] = function POP_MARK () {
		stack = _RPYP_PKL_POP_MARK
	};
	inst_lut[global._pickle_opcodes.DUP] = function DUP () {
		array_push(stack, array_last(stack))
	};
	inst_lut[global._pickle_opcodes.FLOAT] = function FLOAT () {
		var value = rpyp_pkl_read_line(buf)
		array_push(stack, real(value))
	};
	inst_lut[global._pickle_opcodes.INT] = function INT () {
		var value = rpyp_pkl_read_line(buf)
		array_push(stack, real(value))
	};
    function persid_stub () {
		throw "Persistent IDs are not supported. Corrupt persistent file?"
	};
	inst_lut[global._pickle_opcodes.PERSID] = persid_stub
	inst_lut[global._pickle_opcodes.BINPERSID] = persid_stub
	inst_lut[global._pickle_opcodes.STRING] = function STRING () {
		var value = rpyp_pkl_read_line(buf, true)
		array_push(stack, string_copy(value, 2, string_length(value) - 2))
	};
	inst_lut[global._pickle_opcodes.UNICODE] = function UNICODE () {
		var value = rpyp_pkl_read_line(buf, true)
		array_push(stack, string_copy(value, 2, string_length(value) - 2))
	};
	inst_lut[global._pickle_opcodes.APPEND] = function APPEND () {
		var value = array_pop(stack)
		array_push(array_last(stack), value)
	};
	inst_lut[global._pickle_opcodes.DICT] = function DICT () {
		var items = stack
		stack = _RPYP_PKL_POP_MARK
		var dict = new _rpyp_pkl__builtin_dict().__new__([])
		for (var i = 0; i < array_length(items); i += 2)
			dict.__content__[$ items[i]] = items[i + 1]
		array_push(stack, dict)
	};
	inst_lut[global._pickle_opcodes.GET] = function GET () {
		var index = rpyp_pkl_from_decl(rpyp_pkl_read_line(buf))
		array_push(stack, memo[index])
	};
	inst_lut[global._pickle_opcodes.INST] = function INST () {
		var origin = rpyp_pkl_read_line(buf)
		var class = rpyp_pkl_read_line(buf)
		var class_obj = find_class(origin, class)
		var orig_stack = stack
		stack = _RPYP_PKL_POP_MARK
		array_push(stack, new class_obj().__new__(orig_stack))
	};
	inst_lut[global._pickle_opcodes.OBJ] = function OBJ () {
		var args = stack
		stack = _RPYP_PKL_POP_MARK
		var class_obj = stack[0]
		array_delete(stack, 0, 1)
		array_push(stack, new class_obj().__new__(args))
	};
	inst_lut[global._pickle_opcodes.LIST] = function LIST () {
		var items = stack
		stack = _RPYP_PKL_POP_MARK
		var list = new _rpyp_pkl__builtin_list().__new__(items)
		array_push(stack, list)
	};
	inst_lut[global._pickle_opcodes.PUT] = function PUT () {
		var loc = rpyp_pkl_from_decl(rpyp_pkl_read_line(buf))
		memo[loc] = array_last(stack)
	};
	inst_lut[global._pickle_opcodes.SETITEM] = function SETITEM () {
		var value = array_pop(stack)
		var key = array_pop(stack)
		var dict = array_last(stack)
		dict.__content__[$ key] = value
	};
	inst_lut[global._pickle_opcodes.TUPLE] = function TUPLE () {
		var items = stack
		stack = _RPYP_PKL_POP_MARK
		var list = new _rpyp_pkl__builtin_tuple().__new__(items)
		array_push(stack, list)
	};
    function sixty_four_bit_stub () {
		throw "64-bit numbers are currently not supported. Corrupt persistent file?"
	};
	inst_lut[global._pickle_opcodes.BINUNICODE8] = sixty_four_bit_stub
	inst_lut[global._pickle_opcodes.BINBYTES8] = sixty_four_bit_stub
	inst_lut[global._pickle_opcodes.BYTEARRAY8] = sixty_four_bit_stub
	// no bytes support rn
	inst_lut[global._pickle_opcodes.BINBYTES] = function BINBYTES () {
		var len = buffer_read(buf, buffer_u32);
		var str = rpyp_pkl_read_binstring(buf, buffer_tell(buf), len, true);
		array_push(stack, str)
	};
	inst_lut[global._pickle_opcodes.SHORT_BINBYTES] = function SHORT_BINBYTES () {
		var len = buffer_read(buf, buffer_u8);
		var str = rpyp_pkl_read_binstring(buf, buffer_tell(buf), len, true);
		array_push(stack, str)
	};
	inst_lut[global._pickle_opcodes.FROZENSET] = function FROZENSET () {
		var items = stack
		stack = _RPYP_PKL_POP_MARK
		var set = new _rpyp_pkl__builtin_frozenset().__new__([])
		set.__content__ = items
		array_push(stack, set)
	};
	inst_lut[global._pickle_opcodes.NEWOBJ_EX] = function NEWOBJ_EX () {
		/*
		var kwargs = array_pop(stack).__content__
		var args = array_pop(stack).__content__
		var cls = array_pop(stack)

		array_push(stack, new cls().__new__(args, kwargs)) */
		throw "Keyword arguments are not supported."
	};
	inst_lut[global._pickle_opcodes.FRAME] = function FRAME () {
		throw "Framing is not supported."
	};
    function oob_buf_stub () {
		throw "Out-of-band buffers are not supported."
	};
	inst_lut[global._pickle_opcodes.NEXT_BUFFER] = oob_buf_stub
	inst_lut[global._pickle_opcodes.READONLY_BUFFER] = oob_buf_stub
	inst_lut[global._pickle_opcodes.MEMOIZE] = function MEMOIZE () {
		array_push(memo, array_last(stack))
	};
    step = function() {
        var inst = buffer_read(buf, buffer_u8), inst_f
        try {
		    inst_f = inst_lut[inst]
        } catch (_) {
			throw "Unknown opcode " + chr(inst);
        }
        inst_f()
    }
}

///@return {Any}?
function rpy_persistent_read_raw_buffer(buf, find_class=rpyp_pkl_get_class) {
	var correctly_stopped = false;
    var interp = new _rpyp_pkl_interpreter(buf, find_class)
	if buffer_get_size(buf) <= 0
		throw "Buffer is empty";
	try {
		while (true) {
			interp.step()
		}
	} catch (_e) {
		if _e == _RPYP_PKL_STOP_CODE {
			correctly_stopped = true
		} else {
            var poshint = "\nBuffer read to position " + string(buffer_tell(buf))
            if is_string(_e) {
    			_e += poshint
    			throw _e
    		} else {
    			var le_stacktrace = "";
    			for (var i = 0; i < array_length(_e.stacktrace); i++)
    				le_stacktrace += _e.stacktrace[i] + "\n"
    			throw _e.message + poshint + "\n" + le_stacktrace
    		}
        }
	}
    // Well I think the loop will just crash when we reach EOF anyway
    // I'm not calling buffer_tell every iteration
	if !correctly_stopped {
		throw "EOF reached while reading buffer, however STOP is not called"
	}
	return interp.value;
}

///@return {Any}?
function rpy_persistent_read_buffer(cmp_buff, find_class=rpyp_pkl_get_class) {
	var pickle_buff = undefined
	try {
		pickle_buff = buffer_decompress(cmp_buff)
		return rpy_persistent_read_raw_buffer(pickle_buff, find_class)
	} finally {
		if buffer_exists(pickle_buff)
			buffer_delete(pickle_buff)
	}
}
///@return {Any}?
function rpy_persistent_read(fn, find_class=rpyp_pkl_get_class){
	var orig_file = undefined;
	try {
		orig_file = buffer_load(fn);
		if !buffer_exists(orig_file)
			throw "Can't load file " + fn;
		return rpy_persistent_read_buffer(orig_file, find_class)
	} finally {
		if buffer_exists(orig_file)
			buffer_delete(orig_file)
	}
}
///@return {Any}?
function rpy_persistent_read_uncompressed(fn, find_class=rpyp_pkl_get_class){
	var orig_file = undefined;
	try {
		orig_file = buffer_load(fn);
		if !buffer_exists(orig_file)
			throw "Can't load file " + fn;
		return rpy_persistent_read_raw_buffer(orig_file, find_class)
	} finally {
		if buffer_exists(orig_file)
			buffer_delete(orig_file)
	}
}

function rpy_persistent_convert_from_abstract(obj, rem_internal_entries=false) {
    if is_struct(obj) && variable_struct_exists(obj, "__content__") {
    	obj = obj.__content__
    }
    if !is_struct(obj)
        return obj;
	var struct = {};
    var keys = variable_struct_get_names(obj);
    for (var i = 0; i < array_length(keys); i++) {
    	var key = keys[i]
    	var value = obj[$ key]
    	if rem_internal_entries && string_copy(key, 0, 1) == "_"
    		continue;
    	if string_copy(key, 0, 2) == "__" && string_copy(key, string_length(key) - 1, 2) == "__"
    		continue;
    	if is_struct(value) {
    		if variable_struct_exists(value, "__content__")
    			value = value.__content__
    		else
    			value = rpy_persistent_convert_from_abstract(value, false)
    	}
    	struct[$ key] = value
    }
	return struct;
}
