/+
+            Copyright 2023 – 2024 Aya Partridge
+ Distributed under the Boost Software License, Version 1.0.
+     (See accompanying file LICENSE_1_0.txt or copy at
+           http://www.boost.org/LICENSE_1_0.txt)
+/
module isla.txt;

import isla.common: ISLAException;

import std.range.primitives, std.conv, std.string, std.uni;

///Indicates which type is stored in an ISLAValue
enum ISLAType{
	str,
	list,
	map,
}

enum headerVersion = "1";
enum header = "ISLA"~headerVersion;

string toString(ISLAType type) nothrow pure @safe{
	final switch(type){
		case ISLAType.str:  return "str";
		case ISLAType.list: return "list";
		case ISLAType.map:  return "map";
	}
}

struct ISLAValue{
	private union{
		string _str = null;
		ISLAValue[] _list;
		ISLAValue[string] _map;
	}
	private ISLAType _type = ISLAType.str;
	@property type() inout nothrow @nogc pure @safe => _type;
	
	this(string val) nothrow @nogc pure @safe{
		_str = val;
		_type = ISLAType.str;
	}
	this(ISLAValue[] val) nothrow @nogc pure @safe{
		_list = val;
		_type = ISLAType.list;
	}
	this(ISLAValue[string] val) nothrow @nogc pure @safe{
		_map = val;
		_type = ISLAType.map;
	}
	
	this(string[] vals) nothrow pure @safe{
		auto list = new ISLAValue[](vals.length);
		foreach(i, val; vals){
			list[i] = ISLAValue(val);
		}
		_list = list;
		_type = ISLAType.list;
	}
	this(string[string] vals) pure @safe{
		ISLAValue[string] map;
		foreach(key, val; vals){
			map[key] = ISLAValue(val);
		}
		_map = map;
		_type = ISLAType.map;
	}
	
	///Return a string if the `ISLAValue`'s `type` is `str`, otherwise throw an `ISLAException`.
	@property str() inout pure @trusted{
		if(_type != ISLAType.str) throw new ISLAException("Type is `"~_type.toString()~"`, not `str`");
		return _str;
	}
	///Return a string if the `ISLAValue`'s `type` is `str`, otherwise `null`.
	@property strNothrow() inout nothrow @nogc pure @trusted => _type == ISLAType.str ? _str : null;
	
	///Return a list if the `ISLAValue`'s `type` is `list`, otherwise throw an `ISLAException`.
	@property list() inout pure @trusted{
		if(_type != ISLAType.list) throw new ISLAException("Type is `"~_type.toString()~"`, not `list`");
		return _list;
	}
	///Return a list if the `ISLAValue`'s `type` is `list`, otherwise `null`.
	@property listNothrow() inout nothrow @nogc pure @trusted => _type == ISLAType.list ? _list : null;
	
	///Return a map if the `ISLAValue`'s `type` is `map`, otherwise throw an `ISLAException`.
	@property map() inout pure @trusted{
		if(_type != ISLAType.map) throw new ISLAException("Type is "~_type.toString()~"`, not `map`");
		return _map;
	}
	///Return a map if the `ISLAValue`'s `type` is `map`, otherwise `null`.
	@property mapNothrow() inout nothrow @nogc pure @trusted => _type == ISLAType.map ? _map : null;
	
	bool opEquals(scope inout string rhs) inout nothrow @nogc pure @trusted{
		if(_type != ISLAType.str) return false;
		return _str == rhs;
	}
	bool opEquals(scope inout ISLAValue[] rhs) inout nothrow @nogc pure @trusted{
		if(_type != ISLAType.list) return false;
		return _list == rhs;
	}
	bool opEquals(scope inout ISLAValue[string] rhs) inout nothrow @nogc pure @trusted{
		if(_type != ISLAType.map) return false;
		return _map == rhs;
	}
	bool opEquals(inout ISLAValue rhs) inout nothrow @nogc pure @trusted{
		final switch(_type){
			case ISLAType.str:  return _str  == rhs;
			case ISLAType.list: return _list == rhs;
			case ISLAType.map:  return _map  == rhs;
		}
	}
	
	ref inout(ISLAValue) opIndex(size_t i) inout pure @safe{
		auto list = this.list;
		if(i >= list.length) throw new ISLAException("Out of bounds list index");
		return list[i];
	}
	
	ref inout(ISLAValue) opIndex(scope string key) inout pure @safe{
		auto map = this.map;
		if(key !in map) throw new ISLAException("Key not found: " ~ key);
		return map[key];
	}
	
	inout(ISLAValue) get(scope size_t i, return scope inout(ISLAValue) fallback) inout nothrow @nogc pure @trusted =>
		_type == ISLAType.list && i < _list.length ? _list[i] : fallback;
	string get(scope size_t i, return scope string fallback) inout nothrow @nogc pure @trusted =>
		_type == ISLAType.list && i < _list.length && _list[i]._type == ISLAType.str  ? _list[i]._str  : fallback;
	inout(ISLAValue)[] get(scope size_t i, return scope inout(ISLAValue)[] fallback) inout nothrow @nogc pure @trusted =>
		_type == ISLAType.list && i < _list.length && _list[i]._type == ISLAType.list ? _list[i]._list : fallback;
	inout(ISLAValue[string]) get(scope size_t i, return scope inout(ISLAValue[string]) fallback) inout nothrow @nogc pure @trusted =>
		_type == ISLAType.list && i < _list.length && _list[i]._type == ISLAType.map  ? _list[i]._map  : fallback;
	
	T get(alias parse=(a) => a, T)(scope size_t i, return scope T fallback) inout{
		if(_type == ISLAType.list && i < _list.length){
			static if(is(typeof(parse(ISLAValue.init)): T)){
				return parse(_list[i]);
			}else static if(is(typeof(parse("")): T)){
				if(_list[i]._type == ISLAType.str)  return parse(_list[i]._str);
			}else static if(is(typeof(parse([ISLAValue.init])): T)){
				if(_list[i]._type == ISLAType.list) return parse(_list[i]._list);
			}else static if(is(typeof(parse(["": ISLAValue.init])): T)){
				if(_list[i]._type == ISLAType.map)  return parse(_list[i]._map);
			}else static assert(0, "`parse` does not return `"~T.stringof~"` when passed an `ISLAValue` or any of its sub-types");
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
	
	T get(alias parse=(a) => a, T)(scope string key, return scope T fallback) inout{
		if(_type == ISLAType.map){
			if(auto ret = key in _map){
				static if(is(typeof(parse(ISLAValue.init)): T)){
					return parse(*ret);
				}else static if(is(typeof(parse("")): T)){
					if(ret._type == ISLAType.str)  return parse(ret._str);
				}else static if(is(typeof(parse([ISLAValue.init])): T)){
					if(ret._type == ISLAType.list) return parse(ret._list);
				}else static if(is(typeof(parse(["": ISLAValue.init])): T)){
					if(ret._type == ISLAType.map)  return parse(ret._map);
				}else static assert(0, "`parse` does not return `"~T.stringof~"` when passed an `ISLAValue` or any of its sub-types");
			}
		}
		return fallback;
	}
	
	unittest{
		ISLAValue val;
		val = ISLAValue(["50", "-72", "4", "509"]);
		
		assert(val.get(0, "9")  == "50");
		assert(val.get(4, "12") == "12");
		
		assert(val.get!(to!int)(0,  9)   == 50);
		assert(val.get!(to!int)(4, 12)   == 12);
		
		val = ISLAValue(["two": "2", "four": "4", "six": "6"]);
		
		assert(val.get("two",   "7") == "2");
		assert(val.get("eight", "8") == "8");
		
		assert(val.get!(to!int)("two",   7) == 2);
		assert(val.get!(to!int)("eight", 8) == 8);
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
			lines ~= `"`;
		}
	}
	
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
		}
		
		string ret = header;
		foreach(line; lines){
			ret ~= "\n" ~ line;
		}
		return ret;
	}
	
	unittest{
		string val;
		val = ISLAValue([
			"health": ISLAValue("100"),
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
		]).encode();
	}
}

private struct DecodeImpl(R){
	R lines;
	size_t lineNum = 1;
	
	pure @safe:
	bool startLine(ref string line, size_t level, out size_t newLevel){
		if(line.length == 0){
			newLevel = level;
			return false;
		 }
		 
		foreach(ch; line[0..($ < level ? $ : level)]){
			if(ch == '\t'){
				newLevel++;
			}else if(ch == ';'){
				newLevel = level;
				return false;
			}else break;
		}
		if(level > line.length){
			newLevel = level;
			return false;
		}
		line = line[level..$];
		if(line.length == 0) return false;
		if(line[0] == ';') return false;
		if(newLevel < level) return false;
		else if(line[0] == '\t') throw new ISLAException("Nesting level too high for scope with level "~level.to!string()~" on line "~lineNum.to!string());
		return true;
	}
	
	ISLAValue decodeScope(size_t level, ref size_t newLevel){
		while(!lines.empty){
			lines.popFront(); lineNum++;
			auto line = lines.front;
			
			if(!startLine(line, level, newLevel)){
				if(newLevel < level) throw new ISLAException("Scope immediately ended on line "~lineNum.to!string()); //TODO: maybe return null??????
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
			if(!startLine(line, level, newLevel)){
				if(newLevel < level) break;
			}else{
				string key;
				bool escape = false;
				foreach(i, ch; line){
					if(escape){
						if(ch == '=' || ch == ':' || ch == '-'){ //check for valid escapes
							key ~= ch;
						}else{
							key ~= `\`~ch; //otherwise, re-insert the reverse solidus that was skipped
						}
						escape = false;
					}else if(ch == '\\'){
						escape = true; //mark the next char to be checked, and skip adding the reverse solidus to the key for now
					}else if(ch == '='){
						auto val = line[i+1..$];
						ret[key] = val == `"` ? decodeMultiLineValue() : ISLAValue(val);
						break;
					}else if(ch == ':'){
						if(line.length-1 > i) throw new ISLAException("Unexpected data after colon after key on line "~lineNum.to!string()~": "~line[i..$]);
						ret[key] = decodeScope(level+1, newLevel);
						if(newLevel < level) return ret;
						continue decodeLines;
					}else{
						key ~= ch;
					}
				}
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
			if(line == `"`) return ISLAValue(str);
			if(line == `\"`){
				line = line[1..$]; //consume the backslash
			}
			if(firstLine){
				str ~= line;
				firstLine = false;
			}else{
				str ~= '\n' ~ line;
			}
		}
		throw new ISLAException("Multi-line value is never closed before EOF");
	}
	
	ISLAValue decode(){
		if(lines.empty) throw new ISLAException("Empty range provided");
		
		if(lines.front != header) throw new ISLAException("Bad header: "~lines.front);
		
		size_t newLevel;
		return decodeScope(0, newLevel);
	}
}

/**
Decodes a series of lines representing data in the ISLA format.

Params:
	lines = A range of `string`s.
*/
ISLAValue decode(R)(R lines) pure @safe
if(isInputRange!R && is(typeof(lines.front): string)){
	return DecodeImpl!R(lines).decode();
}
unittest{
	ISLAValue val;
	val = isla.txt.decode(header ~ q"isla
-;)
-:3
-\:
isla".splitLines());
	assert(val[0] == ";)");
	assert(val[1] == ":3");
	assert(val[2] == ":");
	
	val = isla.txt.decode(header ~ q"isla
\-3=Minus three
e\=mc^2=Mass–energy equivalence
¯\_(ツ)_/¯=a shrug
\:)=a smiley
isla".splitLines());
	assert("-3" in val);
	assert("e=mc^2" in val);
	assert(`¯\_(ツ)_/¯` in val);
	assert(":)" in val);
	
	val = isla.txt.decode(header ~ q"isla
Quote="
He engraved on it the words:
"And this, too, shall pass away.
\"
"
isla".splitLines());
	assert(val["Quote"] == "He engraved on it the words:\n\"And this, too, shall pass away.\n\"");
	
	val = isla.txt.decode(header ~ q"isla
-:
	-:
		-value

		
	;This is a comment!
	
;Another comment :)
isla".splitLines());
	
	val = isla.txt.decode(header ~ q"isla
health=100
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
isla".splitLines());
	assert(val["health"] == ISLAValue("100"));
	assert(val["health"] == "100");
	assert(val["translations"]["en-UK"]["item.apple.name"] == "Apple");
	assert(val["grid"][1][1] == "5");
}
