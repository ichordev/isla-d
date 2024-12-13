/+
+            Copyright 2023 – 2024 Aya Partridge
+ Distributed under the Boost Software License, Version 1.0.
+     (See accompanying file LICENSE_1_0.txt or copy at
+           http://www.boost.org/LICENSE_1_0.txt)
+/
module isla.txt;

import isla.common;

import std.algorithm.comparison, std.range.primitives, std.conv, std.string, std.uni;

///Indicates which type is stored in an ISLAValue
enum ISLAType{
	str,
	list,
	map,
	none,
}

enum headerVersion = "1";
enum header = "ISLA"~headerVersion;

string toString(ISLAType type) nothrow pure @safe{
	final switch(type){
		case ISLAType.str:  return "str";
		case ISLAType.list: return "list";
		case ISLAType.map:  return "map";
		case ISLAType.none: return "none";
	}
}

struct ISLAValue{
	private union{
		string _str = null;
		ISLAValue[] _list;
		ISLAValue[string] _map;
	}
	private ISLAType _type = ISLAType.none;
	@property type() inout nothrow @nogc pure @safe => _type;
	
	this(string str) nothrow @nogc pure @safe{
		_str = str;
		_type = ISLAType.str;
	}
	this(ISLAValue[] list) nothrow @nogc pure @safe{
		_list = list;
		_type = ISLAType.list;
	}
	this(ISLAValue[string] map) nothrow @nogc pure @safe{
		_map = map;
		_type = ISLAType.map;
	}
	
	this(string[] strList) nothrow pure @safe{
		auto list = new ISLAValue[](strList.length);
		foreach(i, val; strList){
			list[i] = ISLAValue(val);
		}
		_list = list;
		_type = ISLAType.list;
	}
	this(string[string] strMap) pure @safe{
		ISLAValue[string] map;
		foreach(key, val; strMap){
			map[key] = ISLAValue(val);
		}
		_map = map;
		_type = ISLAType.map;
	}
	
	///Return a string if the `ISLAValue`'s `type` is `str`, otherwise throw an `ISLAException`.
	@property str() inout pure @trusted{
		if(_type == ISLAType.str) return _str;
		throw new ISLAException("Type is `"~_type.toString()~"`, not `str`");
	}
	///Return a string if the `ISLAValue`'s `type` is `str`, otherwise `null`.
	@property strNothrow() inout nothrow @nogc pure @trusted => _type == ISLAType.str ? _str : null;
	
	///Return a list if the `ISLAValue`'s `type` is `list`, otherwise throw an `ISLAException`.
	@property list() inout pure @trusted{
		if(_type == ISLAType.list) return _list;
		throw new ISLAException("Type is `"~_type.toString()~"`, not `list`");
	}
	///Return a list if the `ISLAValue`'s `type` is `list`, otherwise `null`.
	@property listNothrow() inout nothrow @nogc pure @trusted => _type == ISLAType.list ? _list : null;
	
	///Return a map if the `ISLAValue`'s `type` is `map`, otherwise throw an `ISLAException`.
	@property map() inout pure @trusted{
		if(_type == ISLAType.map) return _map;
		throw new ISLAException("Type is `"~_type.toString()~"`, not `map`");
	}
	///Return a map if the `ISLAValue`'s `type` is `map`, otherwise `null`.
	@property mapNothrow() inout nothrow @nogc pure @trusted => _type == ISLAType.map ? _map : null;
	
	///Returns `true` if the `ISLAValue`'s `type` is `none`.
	@property none() inout nothrow @nogc pure @safe => _type == ISLAType.none;
	
	bool opEquals(scope inout string rhs) inout nothrow @nogc pure @trusted =>
		_type == ISLAType.str  && _str  == rhs;
	bool opEquals(scope inout ISLAValue[] rhs) inout nothrow @nogc pure @trusted =>
		_type == ISLAType.list && _list == rhs;
	bool opEquals(scope inout ISLAValue[string] rhs) inout nothrow @nogc pure @trusted =>
		_type == ISLAType.map  && _map  == rhs;
	bool opEquals(inout ISLAValue rhs) inout nothrow @nogc pure @trusted{
		final switch(_type){
			case ISLAType.str:  return _str  == rhs;
			case ISLAType.list: return _list == rhs;
			case ISLAType.map:  return _map  == rhs;
			case ISLAType.none: return rhs._type == ISLAType.none;
		}
	}
	
	///Indexes a list. Throws `ISLAException` if the `ISLAValue` is not a list.
	ref inout(ISLAValue) opIndex(size_t i) inout pure @safe{
		auto list = this.list;
		if(i < list.length) return list[i];
		throw new ISLAListIndexException(i, list.length);
	}
	
	///Looks up a key in a map. Throws `ISLAException` if the `ISLAValue` is not a map.
	ref inout(ISLAValue) opIndex(scope string key) inout pure @safe{
		auto map = this.map;
		if(auto val = key in map) return *val;
		throw new ISLAMapKeyException(key);
	}
	
	inout(ISLAValue) get(scope size_t i, return scope inout(ISLAValue) fallback) inout nothrow @nogc pure @trusted =>
		_type == ISLAType.list && i < _list.length ? _list[i] : fallback;
	deprecated("Due to issues with overload ambiguity, only use `get` for getting ISLAValues directly. Please use `getStr` instead for getting type `str` instead")
	string get(scope size_t i, return scope string fallback) inout nothrow @nogc pure @trusted =>
		_type == ISLAType.list && i < _list.length && _list[i]._type == ISLAType.str  ? _list[i]._str  : fallback;
	deprecated("Due to issues with overload ambiguity, only use `get` for getting ISLAValues directly. Please use `getList` instead for getting type `list` instead")
	inout(ISLAValue)[] get(scope size_t i, return scope inout(ISLAValue)[] fallback) inout nothrow @nogc pure @trusted =>
		_type == ISLAType.list && i < _list.length && _list[i]._type == ISLAType.list ? _list[i]._list : fallback;
	deprecated("Due to issues with overload ambiguity, only use `get` for getting ISLAValues directly. Please use `getMap` instead for getting type `map` instead")
	inout(ISLAValue[string]) get(scope size_t i, return scope inout(ISLAValue[string]) fallback) inout nothrow @nogc pure @trusted =>
		_type == ISLAType.list && i < _list.length && _list[i]._type == ISLAType.map  ? _list[i]._map  : fallback;
	string getStr(scope size_t i, return scope string fallback=null) inout nothrow @nogc pure @trusted =>
		_type == ISLAType.list && i < _list.length && _list[i]._type == ISLAType.str  ? _list[i]._str  : fallback;
	inout(ISLAValue)[] getList(scope size_t i, return scope inout(ISLAValue)[] fallback=null) inout nothrow @nogc pure @trusted =>
		_type == ISLAType.list && i < _list.length && _list[i]._type == ISLAType.list ? _list[i]._list : fallback;
	inout(ISLAValue[string]) getMap(scope size_t i, return scope inout(ISLAValue[string]) fallback=null) inout nothrow @nogc pure @trusted =>
		_type == ISLAType.list && i < _list.length && _list[i]._type == ISLAType.map  ? _list[i]._map  : fallback;
	unittest{
		const val = ISLAValue([
			ISLAValue("50"), ISLAValue("-72"), ISLAValue("4"), ISLAValue("509"),
			ISLAValue(["1", "2"]),
			ISLAValue(["one": "1"]),
		]);
		assert(val.get(0, ISLAValue("9")).str  == "50");
		assert(val.get(6, ISLAValue("12")).str == "12");
		assert(val.getStr(0, "9")  == "50");
		assert(val.getStr(6, "12") == "12");
		assert(val.getList(4, [ISLAValue("3")]) == [ISLAValue("1"), ISLAValue("2")]);
		assert(val.getList(7, [ISLAValue("3")]) == [ISLAValue("3")]);
		assert(val.getMap(5, ["two": ISLAValue("2")]) == cast(const)["one": ISLAValue("1")]);
		assert(val.getMap(8, ["two": ISLAValue("2")]) == cast(const)["two": ISLAValue("2")]);
	}
	
	deprecated("`get` with parser cannot support delegates. Please use `parse` instead")
	T get(alias parser=(a) => a, T)(scope size_t i, return scope T fallback) inout{
		if(_type == ISLAType.list && i < _list.length){
			static if(is(typeof(parser(ISLAValue.init)): T)){
				return parser(_list[i]);
			}else static if(is(typeof(parser("")): T)){
				if(_list[i]._type == ISLAType.str)  return parser(_list[i]._str);
			}else static if(is(typeof(parser([ISLAValue.init])): T)){
				if(_list[i]._type == ISLAType.list) return parser(_list[i]._list);
			}else static if(is(typeof(parser(["": ISLAValue.init])): T)){
				if(_list[i]._type == ISLAType.map)  return parser(_list[i]._map);
			}else static assert(0, "`parser` does not return `"~T.stringof~"` when passed an `ISLAValue` or any of its sub-types");
		}
		return fallback;
	}
	
	inout(ISLAValue) get(scope string key, return scope inout(ISLAValue) fallback) inout nothrow @nogc pure @trusted{
		if(_type == ISLAType.map){
			if(auto ret = key in _map){
				return *ret;
			}
		}
		return fallback;
	}
	deprecated("Due to issues with overload ambiguity, only use `get` for getting ISLAValues directly. Please use `getStr` instead for getting type `str` instead")
	string get(scope string key, return scope string fallback) inout nothrow @nogc pure @trusted{
		if(_type == ISLAType.map){
			if(auto ret = key in _map){
				if(ret._type == ISLAType.str){
					return ret._str;
				}
			}
		}
		return fallback;
	}
	deprecated("Due to issues with overload ambiguity, only use `get` for getting ISLAValues directly. Please use `getList` instead for getting type `list` instead")
	inout(ISLAValue)[] get(scope string key, return scope inout(ISLAValue)[] fallback) inout nothrow @nogc pure @trusted{
		if(_type == ISLAType.map){
			if(auto ret = key in _map){
				if(ret._type == ISLAType.list){
					return ret._list;
				}
			}
		}
		return fallback;
	}
	deprecated("Due to issues with overload ambiguity, only use `get` for getting ISLAValues directly. Please use `getMap` instead for getting type `map` instead")
	inout(ISLAValue[string]) get(scope string key, return scope inout(ISLAValue[string]) fallback) inout nothrow @nogc pure @trusted{
		if(_type == ISLAType.map){
			if(auto ret = key in _map){
				if(ret._type == ISLAType.map){
					return ret._map;
				}
			}
		}
		return fallback;
	}
	string getStr(scope string key, return scope string fallback=null) inout nothrow @nogc pure @trusted{
		if(_type == ISLAType.map){
			if(auto ret = key in _map){
				if(ret._type == ISLAType.str){
					return ret._str;
				}
			}
		}
		return fallback;
	}
	inout(ISLAValue)[] getList(scope string key, return scope inout(ISLAValue)[] fallback=null) inout nothrow @nogc pure @trusted{
		if(_type == ISLAType.map){
			if(auto ret = key in _map){
				if(ret._type == ISLAType.list){
					return ret._list;
				}
			}
		}
		return fallback;
	}
	inout(ISLAValue[string]) getMap(scope string key, return scope inout(ISLAValue[string]) fallback=null) inout nothrow @nogc pure @trusted{
		if(_type == ISLAType.map){
			if(auto ret = key in _map){
				if(ret._type == ISLAType.map){
					return ret._map;
				}
			}
		}
		return fallback;
	}
	unittest{
		const val = ISLAValue([
			"two": ISLAValue("2"), "four": ISLAValue("4"), "six": ISLAValue("6"),
			"123": ISLAValue(["1", "2", "3"]), "twotwo": ISLAValue(["two": "2"]),
		]);
		assert(val.get("two",   ISLAValue("7")).str == "2");
		assert(val.get("eight", ISLAValue("8")).str == "8");
		assert(val.getStr("two",   "7") == "2");
		assert(val.getStr("eight", "8") == "8");
		assert(val.getList("123", [ISLAValue("4")]) == ["1", "2", "3"]);
		assert(val.getList("321", [ISLAValue("3"), ISLAValue("2"), ISLAValue("1")]) == ["3", "2", "1"]);
		assert(val.getMap("twotwo", ["four": ISLAValue("4")]) == cast(const)["two": ISLAValue("2")]);
		assert(val.getMap("fourfour", ["four": ISLAValue("4")]) == cast(const)["four": ISLAValue("4")]);
	}
	
	deprecated("`get` with parser cannot support delegates. Please use `parse` instead")
	T get(alias parser=(a) => a, T)(scope string key, return scope T fallback) inout{
		if(_type == ISLAType.map){
			if(auto ret = key in _map){
				static if(is(typeof(parser(ISLAValue.init)): T)){
					return parser(*ret);
				}else static if(is(typeof(parser("")): T)){
					if(ret._type == ISLAType.str)  return parser(ret._str);
				}else static if(is(typeof(parser([ISLAValue.init])): T)){
					if(ret._type == ISLAType.list) return parser(ret._list);
				}else static if(is(typeof(parser(["": ISLAValue.init])): T)){
					if(ret._type == ISLAType.map)  return parser(ret._map);
				}else static assert(0, "`parser` does not return `"~T.stringof~"` when passed an `ISLAValue` or any of its sub-types");
			}
		}
		return fallback;
	}
	
	inout(ISLAValue) opIndexAssign(inout ISLAValue val, size_t i){
		this.list[i] = val;
		return val;
	}
	
	inout(ISLAValue) opIndexAssign(inout ISLAValue val, scope string key){
		this.map[key] = val;
		return val;
	}
	
	inout(ISLAValue)* opBinaryRight(string op: "in")(string key) inout @safe pure =>
		key in map;
	
	int opApply(scope int delegate(size_t, ref ISLAValue) dg){
		int result;
		foreach(index, ref value; listNothrow){
			result = dg(index, value);
			if(result) break;
		}
		return result;
	}
	
	int opApply(scope int delegate(string, ref ISLAValue) dg){
		int result;
		foreach(key, ref value; mapNothrow){
			result = dg(key, value);
			if(result) break;
		}
		return result;
	}
	
	string toString() inout pure nothrow @trusted{
		final switch(_type){
			case ISLAType.str:
				return _str;
			case ISLAType.list:
				string ret = "[";
				if(_list.length > 0){
					foreach(item; _list[0..$-1]){
						ret ~= item.toString() ~ ", ";
					}
					ret ~= _list[$-1].toString();
				}
				return ret ~ "]";
			case ISLAType.map:
				string ret = "[";
				const keys = _map.keys();
				if(keys.length > 0){
					foreach(key; keys[0..$-1]){
						ret ~= key ~ ": " ~ _map[key].toString() ~ ", ";
					}
					ret ~= keys[$-1] ~ ": " ~ _map[keys[$-1]].toString();
				}
				return ret ~ "]";
			case ISLAType.none:
				return "none";
		}
	}
	unittest{
		assert(ISLAValue([
			ISLAValue("a"), ISLAValue("b"), ISLAValue("c"),
			ISLAValue(["d": ISLAValue("e")]), ISLAValue("f"),
		]).toString() == "[a, b, c, [d: e], f]");
	}
	
	private pure inout{
		void encodeScope(scope ref string[] lines, size_t level, bool inList=false) @safe{
			final switch(_type){
				case ISLAType.str:
					encodeValue(lines, inList);
					break;
				case ISLAType.list:
					encodeList(lines, level+1);
					break;
				case ISLAType.map:
					encodeMap(lines, level+1);
					break;
				case ISLAType.none:
					break;
			}
		}
		
		void encodeValue(scope ref string[] lines, bool inList) @trusted{
			foreach(ch; _str){
				if(ch == '\n'){
					encodeMultiLineValue(lines);
					return;
				}
			}
			if((inList && _str == `:`) || _str == `"`){
				lines[$-1] ~= `\` ~ _str;
			}else{
				lines[$-1] ~= _str;
			}
		}
		
		void encodeList(scope ref string[] lines, size_t level) @trusted{
			string indent;
			while(indent.length < level) indent ~= '\t';
			
			foreach(item; _list){
				lines ~= indent ~ "-" ~ (item._type == ISLAType.str ? "" : ":");
				item.encodeScope(lines, level, true);
			}
		}
		
		string encodeKey(string key){
			string ret ;
			size_t prevEsc = 0;
			if(key[0] == '-'){
				ret ~= `\-`;
				prevEsc += 1;
			}
			foreach(i, ch; key){
				if(ch == '=' || ch == ':'){
					ret ~= key[prevEsc..i] ~ `\` ~ ch;
					prevEsc = i+1;
				}
			}
			return ret ~ key[prevEsc..$];
		}
		
		void encodeMap(scope ref string[] lines, size_t level) @trusted{
			string indent;
			while(indent.length < level) indent ~= '\t';
			
			foreach(key, value; _map){
				lines ~= indent ~ encodeKey(key) ~ (value._type == ISLAType.str ? "=" : ":");
				value.encodeScope(lines, level, true);
			}
		}
		
		void encodeMultiLineValue(scope ref string[] lines) @trusted{
			lines[$-1] ~= `"`;
			size_t prevLine = 0;
			foreach(i, ch; _str){
				if(ch == '\n'){
					string line = _str[prevLine..i];
					if(line == `"`){
						lines  ~= `\"`;
					}else{
						lines ~= line;
					}
					prevLine = i+1;
				}
			}
			string line = _str[prevLine..$];
			if(line == `"`){
				lines  ~= `\"`;
			}else{
				lines ~= line;
			}
			lines ~= `"`;
		}
	}
	
	///Convert this object and its children into a valid ISLA text file
	string encode() pure @safe inout{
		string[] lines;
		final switch(_type){
			case ISLAType.str:
				throw new ISLAException("Can only encode list or map, not str");
			case ISLAType.list:
				encodeList(lines, 0);
				break;
			case ISLAType.map:
				encodeMap(lines, 0);
				break;
			case ISLAType.none:
				throw new ISLAException("Can only encode list or map, not none");
		}
		
		string ret = header;
		foreach(line; lines){
			ret ~= "\n" ~ line;
		}
		return ret;
	}
	
	unittest{
		import std.algorithm.searching;
		string val;
		val = ISLAValue([
			"health": ISLAValue("100"),
			"empty": ISLAValue(cast(string[])[]),
			"items": ISLAValue([
				ISLAValue("apple"),
				ISLAValue("apple"),
				ISLAValue("key"),
			]),
			"translations": ISLAValue([
				"en-UK": ISLAValue([
					"item.apple.name": ISLAValue("Apple"),
					"item.apple.description": ISLAValue("A shiny, ripe, red apple that\nfell from a nearby tree.\nIt looks delicious!"),
					"item.key.name": ISLAValue("Key"),
					"item.key.description": ISLAValue("A rusty old-school golden key.\nYou don't know what door it unlocks."),
				]),
			]),
			"grid": ISLAValue([
				ISLAValue([
					ISLAValue("1"),
					ISLAValue("2"),
					ISLAValue("3"),
				]),
				ISLAValue([
					ISLAValue("4"),
					ISLAValue("5"),
					ISLAValue("6"),
				]),
				ISLAValue([
					ISLAValue("7"),
					ISLAValue("8"),
					ISLAValue("9"),
					ISLAValue(":"),
					ISLAValue(`"`),
				]),
			]),
			"-5 - 3": ISLAValue("negative five minus three"),
			"=": ISLAValue("equals"),
			":)": ISLAValue("smiley"),
		]).encode() ~ '\n';
		assert(val.startsWith(isla.txt.header ~ '\n'));
		assert(val.canFind(q"isla
health=100
isla"));
		assert(val.canFind(q"isla
empty:
isla"));
		assert(val.canFind(q"isla
items:
	-apple
	-apple
	-key
isla"));
		assert(val.canFind(q"isla
translations:
	en-UK:
isla"));
		assert(val.canFind(q"isla
		item.apple.name=Apple
isla"));
		assert(val.canFind(q"isla
		item.apple.description="
A shiny, ripe, red apple that
fell from a nearby tree.
It looks delicious!
"
isla"));
		assert(val.canFind(q"isla
		item.key.name=Key
isla"));
		assert(val.canFind(q"isla
		item.key.description="
A rusty old-school golden key.
You don't know what door it unlocks.
"
isla"));
		assert(val.canFind(q"isla
grid:
	-:
		-1
		-2
		-3
	-:
		-4
		-5
		-6
	-:
		-7
		-8
		-9
		-\:
		-\"
isla"));
		assert(val.canFind(q"isla
\-5 - 3=negative five minus three
isla"));
		assert(val.canFind(q"isla
\==equals
isla"));
		assert(val.canFind(q"isla
\:)=smiley
isla"));
	}
}

T parse(alias parser=(a) => a, T)(const ISLAValue val, scope size_t i, return scope T fallback) =>
	val._type == ISLAType.list && i < val._list.length ? parser(val._list[i]) : fallback;
T parseStr(alias parser=(a) => a, T)(const ISLAValue val, scope size_t i, return scope T fallback) =>
	val._type == ISLAType.list && i < val._list.length && val._list[i]._type == ISLAType.str  ? parser(val._list[i]._str)  : fallback;
T parseList(alias parser=(a) => a, T)(const ISLAValue val, scope size_t i, return scope T fallback) =>
	val._type == ISLAType.list && i < val._list.length && val._list[i]._type == ISLAType.list ? parser(val._list[i]._list) : fallback;
T parseMap(alias parser=(a) => a, T)(const ISLAValue val, scope size_t i, return scope T fallback) =>
	val._type == ISLAType.list && i < val._list.length && val._list[i]._type == ISLAType.map  ? parser(val._list[i]._map)  : fallback;
unittest{
	const val = ISLAValue([
		ISLAValue("50"), ISLAValue("-72"), ISLAValue("4"), ISLAValue("509"),
		ISLAValue(["1", "2"]),
		ISLAValue(["one": "1"]),
	]);
	assert(val.parse!(v => v.str.to!int)(0,  9) == 50);
	assert(val.parse!(v => v.str.to!int)(6, 12) == 12);
	assert(val.parseStr!(to!int)(0,  9) == 50);
	assert(val.parseStr!(to!int)(7, 12) == 12);
	import std.algorithm.iteration, std.array, std.typecons;
	assert(val.parseList!(l => l.map!(i => i.str.to!int()).array)(4, [3]) == [1, 2]);
	assert(val.parseList!(l => l.map!(i => i.str.to!int()).array)(8, [3]) == [3]);
	assert(val.parseMap!(m => m.byPair.map!(kv => tuple(kv[0], kv[1].str.to!int())).assocArray)(5, ["two": 2]) == ["one": 1]);
	assert(val.parseMap!(m => m.byPair.map!(kv => tuple(kv[0], kv[1].str.to!int())).assocArray)(9, ["two": 2]) == ["two": 2]);
}

T parse(alias parser=(a) => a, T)(const ISLAValue val, scope string key, return scope T fallback){
	if(val._type == ISLAType.map){
		if(auto ret = key in val._map){
			return parser(*ret);
		}
	}
	return fallback;
}
T parseStr(alias parser=(a) => a, T)(const ISLAValue val, scope string key, return scope T fallback){
	if(val._type == ISLAType.map){
		if(auto ret = key in val._map){
			if(ret._type == ISLAType.str)  return parser(ret._str);
		}
	}
	return fallback;
}
T parseList(alias parser=(a) => a, T)(const ISLAValue val, scope string key, return scope T fallback){
	if(val._type == ISLAType.map){
		if(auto ret = key in val._map){
			if(ret._type == ISLAType.list) return parser(ret._list);
		}
	}
	return fallback;
}
T parseMap(alias parser=(a) => a, T)(const ISLAValue val, scope string key, return scope T fallback){
	if(val._type == ISLAType.map){
		if(auto ret = key in val._map){
			if(ret._type == ISLAType.map)  return parser(ret._map);
		}
	}
	return fallback;
}
unittest{
	const val = ISLAValue([
		"two": ISLAValue("2"), "four": ISLAValue("4"), "six": ISLAValue("6"),
		"123": ISLAValue(["1", "2", "3"]), "twotwo": ISLAValue(["two": "2"]),
	]);
	assert(val.parse!(v => v.str.to!int())("two",   7) == 2);
	assert(val.parse!(v => v.str.to!int())("eight", 8) == 8);
	assert(val.parseStr!(to!int)("two",   7) == 2);
	assert(val.parseStr!(to!int)("eight", 8) == 8);
	import std.algorithm.iteration, std.array, std.typecons;
	assert(val.parseList!(l => l.map!(i => i.str.to!int()).array)("123", [4]) == [1, 2, 3]);
	assert(val.parseList!(l => l.map!(i => i.str.to!int()).array)("321", [3, 2, 1]) == [3, 2, 1]);
	assert(val.parseMap!(m => m.byPair.map!(kv => tuple(kv[0], kv[1].str.to!int())).assocArray)("twotwo", ["four": 4]) == ["two": 2]);
	assert(val.parseMap!(m => m.byPair.map!(kv => tuple(kv[0], kv[1].str.to!int())).assocArray)("fourfour", ["four": 4]) == ["four": 4]);
}

private struct DecodeImpl(R){
	R lines;
	size_t lineNum = 1;
	
	pure @safe:
	/*
	Returns `true` if the line should be parsed by the caller.
	If it returns `false` and `newLevel` is less than `level`, the caller should end its scope.
	*/
	bool startLine(ref string line, size_t level, out size_t newLevel){
		bool isOnlyWhitespace = true;
		findNewLevel: foreach(ch; line[0..min($, level)]){
			switch(ch){
				case '\t':
					newLevel++;
					break;
				default:
					isOnlyWhitespace = false;
					break findNewLevel;
				case ';':
					newLevel = level;
					return false;
			}
		}
		if(level >= line.length){
			if(isOnlyWhitespace) newLevel = level;
			return false;
		}
		
		line = line[level..$];
		if(newLevel < level || line[0] == ';')
			return false;
		if(isOnlyWhitespace && line[0] == '\t')
			throw new ISLAException("Nesting level too high for scope with level "~level.to!string()~" on line "~lineNum.to!string());
		return true;
	}
	
	ISLAValue decodeScope(size_t level, ref size_t newLevel){
		while(!lines.empty){
			lines.popFront(); lineNum++;
			if(lines.empty) return ISLAValue(); //return 'none'
			auto line = lines.front;
			
			if(!startLine(line, level, newLevel)){
				if(newLevel < level) return ISLAValue(); //return 'none'
				else continue;
			}
			
			if(line[0] == '-')
				return ISLAValue(decodeList(level, newLevel));
			else
				return ISLAValue(decodeMap(level, newLevel));
		}
		throw new ISLAException("Expected scope before EOF");
	}
	
	ISLAValue[] decodeList(size_t level, ref size_t newLevel){
		ISLAValue[] ret;
		while(!lines.empty){
			auto line = lines.front;
			if(!startLine(line, level, newLevel)){
				if(newLevel < level) break;
			}else{
				if(line[0] != '-'){
					throw new ISLAException("Expected list item on line "~lineNum.to!string());
				}else if(line == "-:"){
					ret ~= decodeScope(level+1, newLevel);
					if(newLevel < level) break;
					continue;
				}else if(line == `-"`){
					ret ~= decodeMultiLineValue();
				}else if(line == `-\:`){
					ret ~= ISLAValue(":");
				}else{
					ret ~= ISLAValue(line[1..$]);
				}
			}
			lines.popFront(); lineNum++;
		}
		return ret;
	}
	
	ISLAValue[string] decodeMap(size_t level, ref size_t newLevel){
		ISLAValue[string] ret;
		decodeLines: while(!lines.empty){
			auto line = lines.front;
			if(startLine(line, level, newLevel)){
				string key;
				bool escape = false;
				decodeChars: foreach(i, ch; line){
					if(escape){
						switch(ch){
							case '=', ':', '-': //check for valid escapes
								key ~= ch;
								break;
							default: //otherwise, re-insert the reverse solidus that was skipped
								key ~= `\`~ch;
						}
						escape = false;
					}else switch(ch){
						default:
							key ~= ch;
							break;
						case '=':
							auto val = line[i+1..$];
							ret[key] = val == `"` ? decodeMultiLineValue() : ISLAValue(val);
							break decodeChars;
						case ':':
							if(line.length-1 > i) throw new ISLAException("Unexpected data after colon after key on line "~lineNum.to!string()~": "~line[i..$]);
							ret[key] = decodeScope(level+1, newLevel);
							if(newLevel >= level)
								continue decodeLines;
							else
								return ret;
						case '\\':
							escape = true; //mark the next char to be checked, and skip adding the reverse solidus to the key for now
					}
				}
			}else if(newLevel < level){
				break decodeLines;
			}
			lines.popFront(); lineNum++;
		}
		return ret;
	}
	
	ISLAValue decodeMultiLineValue(){
		string str;
		bool firstLine = true;
		while(!lines.empty){
			lines.popFront(); lineNum++;
			auto line = lines.front;
			if(line == `"`)
				return ISLAValue(str);
			if(line == `\"`)
				line = line[1..$]; //consume the backslash
			
			if(firstLine){
				str ~= line;
				firstLine = false;
			}else{
				str ~= '\n' ~ line;
			}
		}
		throw new ISLAException("Multi-line value not closed before EOF");
	}
	
	ISLAValue decode(){
		if(lines.empty) throw new ISLAException("Empty range provided");
		
		if(lines.front != header) throw new ISLAException("Bad header: "~lines.front);
		
		size_t newLevel;
		return decodeScope(0, newLevel);
	}
}

/**
Decodes a series of lines representing data in the ISLA text format.

Params:
	lines = A range of `string`s.
*/
ISLAValue decode(R)(R lines) pure @safe
if(isInputRange!(R, string)){
	return DecodeImpl!R(lines).decode();
}
unittest{
	ISLAValue val;
	val = isla.txt.decode((isla.txt.header ~ '\n' ~ q"isla
-;)
-:3
-\:
isla").lineSplitter());
	assert(val[0] == ";)");
	assert(val[1] == ":3");
	assert(val[2] == ":");
	
	val = isla.txt.decode((isla.txt.header ~ '\n' ~ q"isla
\-3=Minus three
e\=mc^2=Mass–energy equivalence
¯\_(ツ)_/¯=a shrug
\:)=a smiley
isla").lineSplitter());
	assert(val["-3"] == "Minus three");
	assert(val["e=mc^2"] == "Mass–energy equivalence");
	assert(val[`¯\_(ツ)_/¯`] == "a shrug");
	assert(val[":)"] == "a smiley");
	assert(":(" !in val);
	assert(null !in val);
	
	val = isla.txt.decode((isla.txt.header ~ '\n' ~ q"isla
Quote="
He engraved on it the words:
"And this, too, shall pass away.
\"
"
isla").lineSplitter());
	assert(val["Quote"] == "He engraved on it the words:\n\"And this, too, shall pass away.\n\"");
	
	val = isla.txt.decode((isla.txt.header ~ '\n' ~ q"isla
-:
	-:
		-value

		
	;This is a comment!
	
;Another comment :)
isla").lineSplitter());
	assert(val[0][0][0] == "value");
	
	val = isla.txt.decode((isla.txt.header ~ '\n' ~ q"isla
health=100
empty:
items:
	-apple
	-apple
	-key
translations:
	en-UK:
		;United Kingdom English
	
		item.apple.name=Apple
		
		item.apple.description="
A shiny, ripe, red apple that
fell from a nearby tree.
It looks delicious!
"
		item.key.name=Key
		item.key.description="
A rusty old-school golden key.
You don't know what door it unlocks.
"
grid:
	-:
		-1
		-2
		-3
	-:
		-4
		-5
		-6
		
;seven eight nine...
	-:
		-7
		-8
		-9
\-5 - 3=negative five minus three
\==equals
\:)=smiley
isla").lineSplitter());
	assert(val["health"] == ISLAValue("100"));
	assert(val["health"] == "100");
	assert(val["empty"].none);
	assert(val["items"][1] == "apple");
	assert(val["translations"]["en-UK"]["item.apple.name"] == "Apple");
	assert(val["translations"]["en-UK"]["item.key.description"] == "A rusty old-school golden key.\nYou don't know what door it unlocks.");
	assert(val["grid"][1][1] == "5");
	assert(val["-5 - 3"] == "negative five minus three");
	assert(val["="] == "equals");
	assert(val[":)"] == "smiley");
	
	val = isla.txt.decode((isla.txt.header ~ '\n' ~ q"isla
kfs:
	4:
		-:
			time=0
			rot:
				val=0X1.921FB6P-1;0X0P+0;0X0P+0
				ease=none
		-:
			time=7
			rot:
				val=0X0P+0;0X1.921FB6P-1;0X0P+0
				ease=outQuad
		-:
			time=21
			rot:
				val=0X0P+0;0X0P+0;0X0P+0
				ease=inQuad
	5:
		-:
			time=0
			rot:
				val=0X0P+0;0X0P+0;0X1.921FB6P-1
				ease=inOutQuad
		-:
			time=5
			rot:
				val=0X0P+0;0X1.921FB6P-1;0X1.921FB6P-1
				ease=inSin
isla").lineSplitter());
	assert(val == ISLAValue([
		"kfs": ISLAValue([
			"4": ISLAValue([
				ISLAValue([
					"time": ISLAValue("0"),
					"rot": ISLAValue([
						"val": ISLAValue("0X1.921FB6P-1;0X0P+0;0X0P+0"),
						"ease": ISLAValue("none"),
					]),
				]),
				ISLAValue([
					"time": ISLAValue("7"),
					"rot": ISLAValue([
						"val": ISLAValue("0X0P+0;0X1.921FB6P-1;0X0P+0"),
						"ease": ISLAValue("outQuad"),
					]),
				]),
				ISLAValue([
					"time": ISLAValue("21"),
					"rot": ISLAValue([
						"val": ISLAValue("0X0P+0;0X0P+0;0X0P+0"),
						"ease": ISLAValue("inQuad"),
					]),
				]),
			]),
			"5": ISLAValue([
				ISLAValue([
					"time": ISLAValue("0"),
					"rot": ISLAValue([
						"val": ISLAValue("0X0P+0;0X0P+0;0X1.921FB6P-1"),
						"ease": ISLAValue("inOutQuad"),
					]),
				]),
				ISLAValue([
					"time": ISLAValue("5"),
					"rot": ISLAValue([
						"val": ISLAValue("0X0P+0;0X1.921FB6P-1;0X1.921FB6P-1"),
						"ease": ISLAValue("inSin"),
					]),
				]),
			]),
		]),
	]));
}
