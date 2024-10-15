/+
+            Copyright 2023 – 2024 Aya Partridge
+ Distributed under the Boost Software License, Version 1.0.
+     (See accompanying file LICENSE_1_0.txt or copy at
+           http://www.boost.org/LICENSE_1_0.txt)
+/
module isla.bin;

import isla.common: ISLAException;

import std.array, std.bitmanip, std.range.primitives, std.conv;

///Indicates which type is stored in an ISLABinValue
enum ISLABinType{
	bin,
	list,
	map,
}

enum headerVersion = 1;
enum header = cast(immutable(ubyte)[])"ISLAb" ~ [
	cast(ubyte)(headerVersion >> 24),
	cast(ubyte)(headerVersion >> 16),
	cast(ubyte)(headerVersion >>  8),
	cast(ubyte)(headerVersion >>  0),
];

string toString(ISLABinType type) nothrow pure @safe{
	final switch(type){
		case ISLABinType.bin:  return "bin";
		case ISLABinType.list: return "list";
		case ISLABinType.map:  return "map";
	}
}

string toHexString(const(void)[] bin) nothrow pure @safe{
	auto ubyteArr = cast(const(ubyte)[])bin;
	if(ubyteArr.length > 0){
		string ret;
		foreach(b; ubyteArr){
			ret ~= b.toChars!(16, char, LetterCase.upper)().array;
		}
		return ret;
	}else{
		return "null";
	}
}

struct ISLABinValue{
	private union{
		immutable(void)[] _bin = null;
		ISLABinValue[] _list;
		ISLABinValue[immutable(void)[]] _map;
	}
	private ISLABinType _type = ISLABinType.bin;
	@property type() inout nothrow @nogc pure @safe => _type;
	
	this(immutable(void)[] val) nothrow @nogc pure @safe{
		_bin = val;
		_type = ISLABinType.bin;
	}
	this(ISLABinValue[] val) nothrow @nogc pure @safe{
		_list = val;
		_type = ISLABinType.list;
	}
	this(ISLABinValue[immutable(void)[]] val) nothrow @nogc pure @safe{
		_map = val;
		_type = ISLABinType.map;
	}
	
	this(immutable(void)[][] vals) nothrow pure @safe{
		auto list = new ISLABinValue[](vals.length);
		foreach(i, val; vals){
			list[i] = ISLABinValue(val);
		}
		_list = list;
		_type = ISLABinType.list;
	}
	this(immutable(void)[][immutable(void)[]] vals) pure @safe{
		ISLABinValue[immutable(void)[]] map;
		foreach(key, val; vals){
			map[key] = ISLABinValue(val);
		}
		_map = map;
		_type = ISLABinType.map;
	}
	
	///Return a void array if the `ISLABinValue`'s `type` is `bin`, otherwise throw an `ISLAException`.
	@property bin() inout pure @trusted{
		if(_type != ISLABinType.bin) throw new ISLAException("Type is `"~_type.toString()~"`, not `bin`");
		return _bin;
	}
	///Return a void array if the `ISLABinValue`'s `type` is `bin`, otherwise `null`.
	@property binNothrow() inout nothrow @nogc pure @trusted => _type == ISLABinType.bin ? _bin : null;
	
	///Return a list if the `ISLABinValue`'s `type` is `list`, otherwise throw an `ISLAException`.
	@property list() inout pure @trusted{
		if(_type != ISLABinType.list) throw new ISLAException("Type is `"~_type.toString()~"`, not `list`");
		return _list;
	}
	///Return a list if the `ISLABinValue`'s `type` is `list`, otherwise `null`.
	@property listNothrow() inout nothrow @nogc pure @trusted => _type == ISLABinType.list ? _list : null;
	
	///Return a map if the `ISLABinValue`'s `type` is `map`, otherwise throw an `ISLAException`.
	@property map() inout pure @trusted{
		if(_type != ISLABinType.map) throw new ISLAException("Type is "~_type.toString()~"`, not `map`");
		return _map;
	}
	///Return a map if the `ISLABinValue`'s `type` is `map`, otherwise `null`.
	@property mapNothrow() inout nothrow @nogc pure @trusted => _type == ISLABinType.map ? _map : null;
	
	bool opEquals(scope const(void)[] rhs) const nothrow @nogc pure @trusted{
		if(_type != ISLABinType.bin) return false;
		return _bin == rhs;
	}
	bool opEquals(scope const(ISLABinValue)[] rhs) const nothrow @nogc pure @trusted{
		if(_type != ISLABinType.list) return false;
		return _list == rhs;
	}
	bool opEquals(scope const ISLABinValue[immutable(void)[]] rhs) const nothrow @nogc pure @trusted{
		if(_type != ISLABinType.map) return false;
		return _map == rhs;
	}
	bool opEquals(scope const ISLABinValue rhs) const nothrow @nogc pure @trusted{
		final switch(_type){
			case ISLABinType.bin:  return _bin  == rhs;
			case ISLABinType.list: return _list == rhs;
			case ISLABinType.map:  return _map  == rhs;
		}
	}
	
	ref inout(ISLABinValue) opIndex(size_t i) inout pure @safe{
		auto list = this.list;
		if(i < list.length) return list[i];
		throw new ISLAException("Out of bounds list index");
	}
	
	ref inout(ISLABinValue) opIndex(scope const(void)[] key) inout pure @safe{
		auto map = this.map;
		if(auto val = key in map) return *val;
		throw new ISLAException("Key not found: " ~ key.toHexString());
	}
	
	inout(ISLABinValue) get(scope size_t i, return scope inout(ISLABinValue) fallback) inout nothrow @nogc pure @trusted =>
		_type == ISLABinType.list && i < _list.length ? _list[i] : fallback;
	const(void)[] get(scope size_t i, return scope const(void)[] fallback) inout nothrow @nogc pure @trusted =>
		_type == ISLABinType.list && i < _list.length && _list[i]._type == ISLABinType.bin  ? _list[i]._bin  : fallback;
	inout(ISLABinValue)[] get(scope size_t i, return scope inout(ISLABinValue)[] fallback) inout nothrow @nogc pure @trusted =>
		_type == ISLABinType.list && i < _list.length && _list[i]._type == ISLABinType.list ? _list[i]._list : fallback;
	inout(ISLABinValue[immutable(void)[]]) get(scope size_t i, return scope inout(ISLABinValue[immutable(void)[]]) fallback) inout nothrow @nogc pure @trusted =>
		_type == ISLABinType.list && i < _list.length && _list[i]._type == ISLABinType.map  ? _list[i]._map  : fallback;
	
	T get(alias parse=(a) => a, T)(scope size_t i, return scope T fallback) inout{
		if(_type == ISLABinType.list && i < _list.length){
			static if(is(typeof(parse(ISLABinValue.init)): T)){
				return parse(_list[i]);
			}else static if(is(typeof(parse(cast(immutable(void)[])"")): T)){
				if(_list[i]._type == ISLABinType.bin)  return parse(_list[i]._bin);
			}else static if(is(typeof(parse([ISLABinValue.init])): T)){
				if(_list[i]._type == ISLABinType.list) return parse(_list[i]._list);
			}else static if(is(typeof(parse([cast(immutable(void)[])"": ISLABinValue.init])): T)){
				if(_list[i]._type == ISLABinType.map)  return parse(_list[i]._map);
			}else static assert(0, "`parse` does not return `"~T.stringof~"` when passed an `ISLABinValue` or any of its sub-types");
		}
		return fallback;
	}
	
	inout(ISLABinValue) get(scope const(void)[] key, return scope inout(ISLABinValue) fallback) inout nothrow @nogc pure @trusted{
		if(_type == ISLABinType.map){
			if(auto ret = key in _map){
				return *ret;
			}
		}
		return fallback;
	}
	const(void)[] get(scope const(void)[] key, return scope const(void)[] fallback) inout nothrow @nogc pure @trusted{
		if(_type == ISLABinType.map){
			if(auto ret = key in _map){
				if(ret._type == ISLABinType.bin){
					return ret._bin;
				}
			}
		}
		return fallback;
	}
	inout(ISLABinValue)[] get(scope const(void)[] key, return scope inout(ISLABinValue)[] fallback) inout nothrow @nogc pure @trusted{
		if(_type == ISLABinType.map){
			if(auto ret = key in _map){
				if(ret._type == ISLABinType.list){
					return ret._list;
				}
			}
		}
		return fallback;
	}
	inout(ISLABinValue[immutable(void)[]]) get(scope const(void)[] key, return scope inout(ISLABinValue[immutable(void)[]]) fallback) inout nothrow @nogc pure @trusted{
		if(_type == ISLABinType.map){
			if(auto ret = key in _map){
				if(ret._type == ISLABinType.map){
					return ret._map;
				}
			}
		}
		return fallback;
	}
	
	T get(alias parse=(a) => a, T)(scope const(void)[] key, return scope T fallback) inout{
		if(_type == ISLABinType.map){
			if(auto ret = key in _map){
				static if(is(typeof(parse(ISLABinValue.init)): T)){
					return parse(*ret);
				}else static if(is(typeof(parse(cast(immutable(void)[])"")): T)){
					if(ret._type == ISLABinType.bin)  return parse(ret._bin);
				}else static if(is(typeof(parse([ISLABinValue.init])): T)){
					if(ret._type == ISLABinType.list) return parse(ret._list);
				}else static if(is(typeof(parse([cast(immutable(void)[])"": ISLABinValue.init])): T)){
					if(ret._type == ISLABinType.map)  return parse(ret._map);
				}else static assert(0, "`parse` does not return `"~T.stringof~"` when passed an `ISLABinValue` or any of its sub-types");
			}
		}
		return fallback;
	}
	
	unittest{
		ISLABinValue val;
		val = ISLABinValue(["50", "-72", "4", "509"]);
		
		assert(val.get(0, "9")  == "50");
		assert(val.get(4, "12") == "12");
		
		static int toInt(const(void)[] bin) =>
			(cast(string)bin).to!int();
		
		assert(val.get!(toInt)(0,  9)   == 50);
		assert(val.get!(toInt)(4, 12)   == 12);
		
		val = ISLABinValue(["two": "2", "four": "4", "six": "6"]);
		
		assert(val.get("two",   "7") == "2");
		assert(val.get("eight", "8") == "8");
		
		assert(val.get!(toInt)("two",   7) == 2);
		assert(val.get!(toInt)("eight", 8) == 8);
	}
	
	inout(ISLABinValue) opIndexAssign(inout(ISLABinValue) val, size_t i){
		this.list[i] = val;
		return val;
	}
	
	inout(ISLABinValue) opIndexAssign(inout(ISLABinValue) val, scope const(void)[] key){
		this.map[key] = val;
		return val;
	}
	
	inout(ISLABinValue)* opBinaryRight(string op: "in")(const(void)[] key) inout @safe pure =>
		key in map;
	
	int opApply(scope int delegate(size_t, ref ISLABinValue) dg){
		int result;
		foreach(index, ref value; listNothrow){
			result = dg(index, value);
			if(result) break;
		}
		return result;
	}
	
	int opApply(scope int delegate(const(void)[], ref ISLABinValue) dg){
		int result;
		foreach(key, ref value; mapNothrow){
			result = dg(key, value);
			if(result) break;
		}
		return result;
	}
	
	string toString() inout pure nothrow @trusted{
		final switch(_type){
			case ISLABinType.bin:
				return _bin.toHexString();
			case ISLABinType.list:
				string ret = "[";
				if(_list.length > 0){
					foreach(item; _list[0..$-1]){
						ret ~= item.toString() ~ ", ";
					}
					ret ~= _list[$-1].toString();
				}
				return ret ~ "]";
			case ISLABinType.map:
				string ret = "[";
				const keys = _map.keys();
				if(keys.length > 0){
					foreach(key; keys[0..$-1]){
						ret ~= key.toHexString() ~ ": " ~ _map[key].toString() ~ ", ";
					}
					ret ~= keys[$-1].toHexString() ~ ": " ~ _map[keys[$-1]].toString();
				}
				return ret ~ "]";
		}
	}
	unittest{
		assert(ISLABinValue([
			ISLABinValue("a"), ISLABinValue("b"), ISLABinValue("c"),
			ISLABinValue(["d": ISLABinValue("e")]), ISLABinValue("f"),
		]).toString() == "[61, 62, 63, [64: 65], 66]");
	}
	
	private void encodeScope(scope ref void[] data) inout pure @trusted{
		size_t prevDataLen = data.length;
		final switch(_type){
			case ISLABinType.bin:
				static if(size_t.sizeof > 7)
					ulong len = cast(ulong)_bin.length & 0x00FF_FFFF_FFFF_FFFFUL;
				else
					size_t len = _bin.length;
				data.length += ulong.sizeof + len;
				(cast(ubyte[])data).write!(ulong, Endian.littleEndian)(len, &prevDataLen);
				
				data[prevDataLen..prevDataLen+len] = _bin[0..len];
				break;
			case ISLABinType.list:
				static if(size_t.sizeof > 7)
					ulong len = cast(ulong)_list.length & 0x00FF_FFFF_FFFF_FFFFUL;
				else
					size_t len = _list.length;
				data.length += ulong.sizeof;
				(cast(ubyte[])data).write!(ulong, Endian.littleEndian)(0x01_00000000000000UL | len, prevDataLen);
				
				foreach(item; _list[0..len]){
					item.encodeScope(data);
				}
				break;
			case ISLABinType.map:
				static if(size_t.sizeof > 7)
					ulong len = cast(ulong)_map.length & 0x00FF_FFFF_FFFF_FFFFUL;
				else
					size_t len = _map.length;
				data.length += ulong.sizeof;
				(cast(ubyte[])data).write!(ulong, Endian.littleEndian)(0x02_00000000000000UL | len, prevDataLen);
				
				foreach(key, value; _map){
					prevDataLen = data.length;
					data.length += ulong.sizeof;
					(cast(ubyte[])data).write!(ulong, Endian.littleEndian)(key.length, prevDataLen);
					value.encodeScope(data);
				}
				break;
		}
	}
	
	void[] encode() pure @safe inout{
		void[] data;
		this.encodeScope(data);
		return header ~ data;
	}
	
	unittest{
		void[] val;
		val = ISLABinValue([
			"health": ISLABinValue("100"),
			"items": ISLABinValue([
				ISLABinValue("apple"),
				ISLABinValue("apple"),
				ISLABinValue("key"),
			]),
			"translations": ISLABinValue([
				"en-UK": ISLABinValue([
					"item.apple.name": ISLABinValue("Apple"),
					"item.apple.description": ISLABinValue("A shiny, ripe, red apple that\nfell from a nearby tree.\nIt looks delicious!"),
					"item.key.name": ISLABinValue("Key"),
					"item.key.description": ISLABinValue("A rusty old-school golden key.\nYou don't know what door it unlocks."),
				]),
			]),
			"grid": ISLABinValue([
				ISLABinValue([
					ISLABinValue("1"),
					ISLABinValue("2"),
					ISLABinValue("3"),
				]),
				ISLABinValue([
					ISLABinValue("4"),
					ISLABinValue("5"),
					ISLABinValue("6"),
				]),
				ISLABinValue([
					ISLABinValue("7"),
					ISLABinValue("8"),
					ISLABinValue("9"),
					ISLABinValue(":"),
					ISLABinValue(`"`),
				]),
			]),
			"-5 - 3": ISLABinValue("negative five minus three"),
			"=": ISLABinValue("equals"),
			":)": ISLABinValue("smiley"),
		]).encode();
	}
}
/+
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
	
	ISLABinValue decodeScope(size_t level, ref size_t newLevel){
		while(!lines.empty){
			lines.popFront(); lineNum++;
			auto line = lines.front;
			
			if(!startLine(line, level, newLevel)){
				if(newLevel < level) throw new ISLAException("Scope immediately ended on line "~lineNum.to!string()); //TODO: maybe return null??????
				else continue;
			}
			
			if(line[0] == '-')
				return ISLABinValue(decodeList(level, newLevel));
			else
				return ISLABinValue(decodeMap(level, newLevel));
		}
		throw new ISLAException("Expected scope before EOF");
	}
	
	ISLABinValue[] decodeList(size_t level, ref size_t newLevel){
		ISLABinValue[] ret;
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
					ret ~= ISLABinValue(":");
				}else{
					ret ~= ISLABinValue(line[1..$]);
				}
			}
			lines.popFront(); lineNum++;
		}
		return ret;
	}
	
	ISLABinValue[immutable(void)[]] decodeMap(size_t level, ref size_t newLevel){
		ISLABinValue[immutable(void)[]] ret;
		decodeLines: while(!lines.empty){
			auto line = lines.front;
			if(!startLine(line, level, newLevel)){
				if(newLevel < level) break;
			}else{
				immutable(void)[] key;
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
						ret[key] = val == `"` ? decodeMultiLineValue() : ISLABinValue(val);
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
	
	ISLABinValue decode(){
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
ISLABinValue decode(R)(R lines) pure @safe
if(isInputRange!R && is(typeof(lines.front): string)){
	return DecodeImpl!R(lines).decode();
}
unittest{
	ISLABinValue val;
	val = isla.bin.decode(header ~
		//TT LLLLLLLLLLLLLL (1 byte for type, 7 bytes for length)
		x"01 00000000000004" ~ //type 1 (list), 4 entries
		x"00 00000000000002" ~ cast(immutable(void)[])";)" ~ //type 0 (bin), 2 bytes
		x"00 00000000000002" ~ cast(immutable(void)[])":3" ~ //type 0 (bin), 2 bytes
		x"00 00000000000000" ~                               //type 0 (bin), 0 bytes (null)
		x"00 00000000000001" ~ cast(immutable(void)[])":"    //type 0 (bin), 1 byte
	);
	assert(val[0] == ";)");
	assert(val[1] == ":3");
	assert(val[2] == null);
	assert(val[3] == ":");
	
	val = isla.bin.decode(header ~
		x"02 00000000000004" ~ //type 2 (map), 4 entries
		x"0000000000000002" ~ cast(immutable(void)[])"-3"         ~ x"00 0000000000000B" ~ cast(immutable(void)[])"Minus three" ~
		x"0000000000000006" ~ cast(immutable(void)[])"e=mc^2"     ~ x"00 00000000000019" ~ cast(immutable(void)[])"Mass–energy equivalence" ~
		x"000000000000000D" ~ cast(immutable(void)[])`¯\_(ツ)_/¯` ~ x"00 00000000000007" ~ cast(immutable(void)[])"a shrug" ~
		x"0000000000000002" ~ cast(immutable(void)[])":)"         ~ x"00 00000000000008" ~ cast(immutable(void)[])"a smiley"
	);
	assert("-3" in val);
	assert("e=mc^2" in val);
	assert(`¯\_(ツ)_/¯` in val);
	assert(":)" in val);
	
	val = isla.bin.decode(header ~
		x"02 00000000000001" ~ //type 2 (map), 1 entry
		x"0000000000000005"  ~ cast(immutable(void)[])"Quote" ~
		x"00 0000000000003F" ~ cast(immutable(void)[])"He engraved on it the words:\n\"And this, too, shall pass away.\n\""
	);
	assert(val["Quote"] == "He engraved on it the words:\n\"And this, too, shall pass away.\n\"");
	/+
	val = isla.bin.decode(header ~ q"isla
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
	assert(val["health"] == ISLABinValue("100"));
	assert(val["health"] == "100");
	assert(val["translations"]["en-UK"]["item.apple.name"] == "Apple");
	assert(val["grid"][1][1] == "5");
	+/
}
+/