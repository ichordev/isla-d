/+
+            Copyright 2023 – 2024 Aya Partridge
+ Distributed under the Boost Software License, Version 1.0.
+     (See accompanying file LICENSE_1_0.txt or copy at
+           http://www.boost.org/LICENSE_1_0.txt)
+/
module isla.bin;

import isla.common;

import std.bitmanip, std.conv, std.exception, std.range.primitives;

///Indicates which type is stored in an ISLABinValue
enum ISLABinType{
	bin,
	list,
	map,
}

enum headerVersion = 1;
enum header = cast(immutable(ubyte)[])"ISLAb" ~
	cast(ubyte)(headerVersion >> 16) ~
	cast(ubyte)(headerVersion >>  8) ~
	cast(ubyte)(headerVersion >>  0);

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
		import std.array, std.string;
		string ret;
		foreach(b; ubyteArr[0..$-1]){
			ret ~= b.toChars!(16, char, LetterCase.upper)().array.rightJustify(2, '0') ~ ' ';
		}
		ret ~= ubyteArr[$-1].toChars!(16, char, LetterCase.upper)().array.rightJustify(2, '0');
		return ret;
	}else{
		return "null";
	}
}

struct ISLABinValue{
	enum lengthBits = 28;
	enum typeBits   =  4;
	enum maxTypes   = (1U<<  typeBits)-1;
	enum maxLength  = (1U<<lengthBits)-1;
	
	private union{
		immutable(void)[] _bin = null;
		ISLABinValue[] _list;
		ISLABinValue[immutable(void)[]] _map;
	}
	private ISLABinType _type = ISLABinType.bin;
	@property type() inout nothrow @nogc pure @safe => _type;
	
	this(immutable(void)[] bin) nothrow @nogc pure @safe{
		_bin = bin;
		_type = ISLABinType.bin;
	}
	this(ISLABinValue[] list) nothrow @nogc pure @safe{
		_list = list;
		_type = ISLABinType.list;
	}
	this(ISLABinValue[immutable(void)[]] map) nothrow @nogc pure @safe{
		_map = map;
		_type = ISLABinType.map;
	}
	
	this(immutable(void)[][] binList) nothrow pure @safe{
		auto list = new ISLABinValue[](binList.length);
		foreach(i, val; binList){
			list[i] = ISLABinValue(val);
		}
		_list = list;
		_type = ISLABinType.list;
	}
	this(immutable(void)[][immutable(void)[]] binMap) pure @safe{
		ISLABinValue[immutable(void)[]] map;
		foreach(key, val; binMap){
			map[key] = ISLABinValue(val);
		}
		_map = map;
		_type = ISLABinType.map;
	}
	
	///Return a void array if the `ISLABinValue`'s `type` is `bin`, otherwise throw an `ISLAException`.
	@property bin() inout pure @trusted{
		if(_type == ISLABinType.bin) return _bin;
		throw new ISLAException("Type is `"~_type.toString()~"`, not `bin`");
	}
	///Return a void array if the `ISLABinValue`'s `type` is `bin`, otherwise `null`.
	@property binNothrow() inout nothrow @nogc pure @trusted => _type == ISLABinType.bin ? _bin : null;
	
	///Return a list if the `ISLABinValue`'s `type` is `list`, otherwise throw an `ISLAException`.
	@property list() inout pure @trusted{
		if(_type == ISLABinType.list) return _list;
		throw new ISLAException("Type is `"~_type.toString()~"`, not `list`");
	}
	///Return a list if the `ISLABinValue`'s `type` is `list`, otherwise `null`.
	@property listNothrow() inout nothrow @nogc pure @trusted => _type == ISLABinType.list ? _list : null;
	
	///Return a map if the `ISLABinValue`'s `type` is `map`, otherwise throw an `ISLAException`.
	@property map() inout pure @trusted{
		if(_type == ISLABinType.map) return _map;
		throw new ISLAException("Type is `"~_type.toString()~"`, not `map`");
	}
	///Return a map if the `ISLABinValue`'s `type` is `map`, otherwise `null`.
	@property mapNothrow() inout nothrow @nogc pure @trusted => _type == ISLABinType.map ? _map : null;
	
	bool opEquals(scope const(void)[] rhs) const nothrow @nogc pure @trusted =>
		_type == ISLABinType.bin  && _bin  == rhs;
	bool opEquals(scope const(ISLABinValue)[] rhs) const nothrow @nogc pure @trusted =>
		_type == ISLABinType.list && _list == rhs;
	bool opEquals(scope const ISLABinValue[immutable(void)[]] rhs) const nothrow @nogc pure @trusted =>
		_type == ISLABinType.map  && _map  == rhs;
	bool opEquals(scope const ISLABinValue rhs) const nothrow @nogc pure @trusted{
		final switch(_type){
			case ISLABinType.bin:  return _bin  == rhs;
			case ISLABinType.list: return _list == rhs;
			case ISLABinType.map:  return _map  == rhs;
		}
	}
	
	///Indexes a list. Throws `ISLAException` if the `ISLABinValue` is not a list.
	ref inout(ISLABinValue) opIndex(size_t i) inout pure @safe{
		auto list = this.list;
		if(i < list.length) return list[i];
		throw new ISLAListIndexException(i, list.length);
	}
	
	///Looks up a key in a map. Throws `ISLAException` if the `ISLABinValue` is not a map.
	ref inout(ISLABinValue) opIndex(scope const(void)[] key) inout pure @safe{
		auto map = this.map;
		if(auto val = key in map) return *val;
		throw new ISLAMapKeyException(key.toHexString());
	}
	
	inout(ISLABinValue) get(scope size_t i, return scope inout(ISLABinValue) fallback) inout nothrow @nogc pure @trusted =>
		_type == ISLABinType.list && i < _list.length ? _list[i] : fallback;
	deprecated("Due to issues with overload ambiguity, only use `get` for getting ISLAValues directly. Please use `getBin` instead for getting type `bin` instead")
	const(void)[] get(scope size_t i, return scope const(void)[] fallback) inout nothrow @nogc pure @trusted =>
		_type == ISLABinType.list && i < _list.length && _list[i]._type == ISLABinType.bin  ? _list[i]._bin  : fallback;
	deprecated("Due to issues with overload ambiguity, only use `get` for getting ISLAValues directly. Please use `getList` instead for getting type `list` instead")
	inout(ISLABinValue)[] get(scope size_t i, return scope inout(ISLABinValue)[] fallback) inout nothrow @nogc pure @trusted =>
		_type == ISLABinType.list && i < _list.length && _list[i]._type == ISLABinType.list ? _list[i]._list : fallback;
	deprecated("Due to issues with overload ambiguity, only use `get` for getting ISLAValues directly. Please use `getMap` instead for getting type `map` instead")
	inout(ISLABinValue[immutable(void)[]]) get(scope size_t i, return scope inout(ISLABinValue[immutable(void)[]]) fallback) inout nothrow @nogc pure @trusted =>
		_type == ISLABinType.list && i < _list.length && _list[i]._type == ISLABinType.map  ? _list[i]._map  : fallback;
	const(void)[] getBin(scope size_t i, return scope const(void)[] fallback) inout nothrow @nogc pure @trusted =>
		_type == ISLABinType.list && i < _list.length && _list[i]._type == ISLABinType.bin  ? _list[i]._bin  : fallback;
	inout(ISLABinValue)[] getList(scope size_t i, return scope inout(ISLABinValue)[] fallback) inout nothrow @nogc pure @trusted =>
		_type == ISLABinType.list && i < _list.length && _list[i]._type == ISLABinType.list ? _list[i]._list : fallback;
	inout(ISLABinValue[immutable(void)[]]) getMap(scope size_t i, return scope inout(ISLABinValue[immutable(void)[]]) fallback) inout nothrow @nogc pure @trusted =>
		_type == ISLABinType.list && i < _list.length && _list[i]._type == ISLABinType.map  ? _list[i]._map  : fallback;
	unittest{
		const val = ISLABinValue([
			ISLABinValue("50"), ISLABinValue("-72"), ISLABinValue("4"), ISLABinValue("509"),
			ISLABinValue(["1", "2"]),
			ISLABinValue(["one": "1"]),
		]);
		assert(val.get(0, ISLABinValue("9")).bin  == "50");
		assert(val.get(6, ISLABinValue("12")).bin == "12");
		assert(val.getBin(0, "9")  == "50");
		assert(val.getBin(7, "12") == "12");
		assert(val.getList(4, [ISLABinValue("3")]) == [ISLABinValue("1"), ISLABinValue("2")]);
		assert(val.getList(8, [ISLABinValue("3")]) == [ISLABinValue("3")]);
		assert(val.getMap(5, [cast(immutable(void)[])"two": ISLABinValue("2")]) == cast(const)[cast(immutable(void)[])"one": ISLABinValue("1")]);
		assert(val.getMap(9, [cast(immutable(void)[])"two": ISLABinValue("2")]) == cast(const)[cast(immutable(void)[])"two": ISLABinValue("2")]);
	}
	
	deprecated("`get` with parser cannot support delegates. Please use `parse` instead")
	T get(alias parser=(a) => a, T)(scope size_t i, return scope T fallback) inout{
		if(_type == ISLABinType.list && i < _list.length){
			static if(is(typeof(parser(ISLABinValue.init)): T)){
				return parser(_list[i]);
			}else static if(is(typeof(parser(cast(immutable(void)[])"")): T)){
				if(_list[i]._type == ISLABinType.bin)  return parser(_list[i]._bin);
			}else static if(is(typeof(parser([ISLABinValue.init])): T)){
				if(_list[i]._type == ISLABinType.list) return parser(_list[i]._list);
			}else static if(is(typeof(parser([cast(immutable(void)[])"": ISLABinValue.init])): T)){
				if(_list[i]._type == ISLABinType.map)  return parser(_list[i]._map);
			}else static assert(0, "`parser` does not return `"~T.stringof~"` when passed an `ISLABinValue` or any of its sub-types");
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
	deprecated("Due to issues with overload ambiguity, only use `get` for getting ISLAValues directly. Please use `getBin` instead for getting type `bin` instead")
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
	deprecated("Due to issues with overload ambiguity, only use `get` for getting ISLAValues directly. Please use `getList` instead for getting type `list` instead")
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
	deprecated("Due to issues with overload ambiguity, only use `get` for getting ISLAValues directly. Please use `getMap` instead for getting type `map` instead")
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
	const(void)[] getBin(scope const(void)[] key, return scope const(void)[] fallback) inout nothrow @nogc pure @trusted{
		if(_type == ISLABinType.map){
			if(auto ret = key in _map){
				if(ret._type == ISLABinType.bin){
					return ret._bin;
				}
			}
		}
		return fallback;
	}
	inout(ISLABinValue)[] getList(scope const(void)[] key, return scope inout(ISLABinValue)[] fallback) inout nothrow @nogc pure @trusted{
		if(_type == ISLABinType.map){
			if(auto ret = key in _map){
				if(ret._type == ISLABinType.list){
					return ret._list;
				}
			}
		}
		return fallback;
	}
	inout(ISLABinValue[immutable(void)[]]) getMap(scope const(void)[] key, return scope inout(ISLABinValue[immutable(void)[]]) fallback) inout nothrow @nogc pure @trusted{
		if(_type == ISLABinType.map){
			if(auto ret = key in _map){
				if(ret._type == ISLABinType.map){
					return ret._map;
				}
			}
		}
		return fallback;
	}
	unittest{
		const val = ISLABinValue([
			"two": ISLABinValue("2"), "four": ISLABinValue("4"), "six": ISLABinValue("6"),
			"123": ISLABinValue(["1", "2", "3"]), "twotwo": ISLABinValue(["two": "2"]),
		]);
		assert(val.get("two",   ISLABinValue("7")).bin == "2");
		assert(val.get("eight", ISLABinValue("8")).bin == "8");
		assert(val.getBin("two",   "7") == "2");
		assert(val.getBin("eight", "8") == "8");
		assert(val.getList("123", [ISLABinValue("4")]) == ["1", "2", "3"]);
		assert(val.getList("321", [ISLABinValue("3"), ISLABinValue("2"), ISLABinValue("1")]) == ["3", "2", "1"]);
		assert(val.getMap("twotwo", [cast(immutable(void)[])"four": ISLABinValue("4")]) == cast(const)[cast(immutable(void)[])"two": ISLABinValue("2")]);
		assert(val.getMap("fourfour", [cast(immutable(void)[])"four": ISLABinValue("4")]) == cast(const)[cast(immutable(void)[])"four": ISLABinValue("4")]);
	}
	
	deprecated("`get` with parser cannot support delegates. Please use `parse` instead")
	T get(alias parser=(a) => a, T)(scope const(void)[] key, return scope T fallback) inout{
		if(_type == ISLABinType.map){
			if(auto ret = key in _map){
				static if(is(typeof(parser(ISLABinValue.init)): T)){
					return parser(*ret);
				}else static if(is(typeof(parser(cast(immutable(void)[])"")): T)){
					if(ret._type == ISLABinType.bin)  return parser(ret._bin);
				}else static if(is(typeof(parser([ISLABinValue.init])): T)){
					if(ret._type == ISLABinType.list) return parser(ret._list);
				}else static if(is(typeof(parser([cast(immutable(void)[])"": ISLABinValue.init])): T)){
					if(ret._type == ISLABinType.map)  return parser(ret._map);
				}else static assert(0, "`parser` does not return `"~T.stringof~"` when passed an `ISLABinValue` or any of its sub-types");
			}
		}
		return fallback;
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
	
	private void encodeScope(scope ref ubyte[] data) inout pure @trusted{
		size_t prevDataLen = data.length;
		final switch(_type){
			case ISLABinType.bin:
				static if(size_t.sizeof >= 4){
					if(_bin.length > maxLength) throw new ISLAEncodeTooLongException("bin", _bin.length, maxLength);
				}
				data.length += uint.sizeof + _bin.length;
				data.write!(uint, Endian.littleEndian)(cast(uint)_bin.length, &prevDataLen);
				
				data[prevDataLen..prevDataLen+_bin.length] = (cast(immutable(ubyte)[])_bin)[];
				break;
			case ISLABinType.list:
				static if(size_t.sizeof >= 4){
					if(_list.length > maxLength) throw new ISLAEncodeTooLongException("list", _list.length, maxLength);
				}
				data.length += uint.sizeof;
				data.write!(uint, Endian.littleEndian)(0x1_0000000U | cast(uint)_list.length, prevDataLen);
				
				foreach(item; _list){
					item.encodeScope(data);
				}
				break;
			case ISLABinType.map:
				static if(size_t.sizeof >= 4){
					if(_map.length > maxLength) throw new ISLAEncodeTooLongException("map", _map.length, maxLength);
				}
				data.length += uint.sizeof;
				data.write!(uint, Endian.littleEndian)(0x2_0000000U | cast(uint)_map.length, prevDataLen);
				
				foreach(key, value; _map){
					static if(size_t.sizeof > uint.sizeof){
						if(key.length > uint.max) throw new ISLAEncodeTooLongException("map key", key.length, uint.max);
					}
					prevDataLen = data.length;
					data.length += uint.sizeof + key.length;
					data.write!(uint, Endian.littleEndian)(cast(uint)key.length, &prevDataLen);
					data[prevDataLen..prevDataLen+key.length] = (cast(immutable(ubyte)[])key)[];
					
					value.encodeScope(data);
				}
				break;
		}
	}
	
	///Convert this object and its children into a valid ISLA binary file
	ubyte[] encode() pure @safe inout{
		ubyte[] data;
		this.encodeScope(data);
		return header ~ data;
	}
	unittest{
		import std.algorithm.searching;
		ubyte[] val;
		val = ISLABinValue([
			"health": ISLABinValue(x"64"),
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
					ISLABinValue(x"01"),
					ISLABinValue(x"02"),
					ISLABinValue(x"03"),
				]),
				ISLABinValue([
					ISLABinValue(x"04"),
					ISLABinValue(x"05"),
					ISLABinValue(x"06"),
				]),
				ISLABinValue([
					ISLABinValue(x"07"),
					ISLABinValue(x"08"),
					ISLABinValue(x"09"),
				]),
			]),
			"-5 - 3": ISLABinValue("negative five minus three"),
			"=": ISLABinValue("equals"),
			":)": ISLABinValue("smiley"),
		]).encode();
		
		alias nToLE = nativeToLittleEndian;
		assert(val.startsWith(isla.bin.header ~ nToLE(0x2_0000007U))); //header; type 2 (map); length 
		assert(val.canFind(nToLE(0x00000006U) ~ cast(ubyte[])"health" ~ nToLE(0x0_0000001U) ~ x"64"));
		assert(val.canFind(nToLE(0x00000005U) ~ cast(ubyte[])"items"  ~ nToLE(0x1_0000003U) ~
			nToLE(0x0_0000005) ~ cast(ubyte[])"apple" ~
			nToLE(0x0_0000005) ~ cast(ubyte[])"apple" ~
			nToLE(0x0_0000003) ~ cast(ubyte[])"key"
		));
		assert(val.canFind(nToLE(0x0000000CU) ~ cast(ubyte[])"translations"  ~ nToLE(0x2_0000001U) ~
			nToLE(0x00000005U) ~ cast(ubyte[])"en-UK"  ~ nToLE(0x2_0000004U)
		));
		assert(val.canFind(nToLE(0x0000000FU) ~ cast(ubyte[])"item.apple.name"        ~ nToLE(0x0_0000005U) ~ cast(ubyte[])"Apple"));
		assert(val.canFind(nToLE(0x00000016U) ~ cast(ubyte[])"item.apple.description" ~ nToLE(0x0_000004AU) ~ cast(ubyte[])"A shiny, ripe, red apple that\nfell from a nearby tree.\nIt looks delicious!"));
		assert(val.canFind(nToLE(0x0000000DU) ~ cast(ubyte[])"item.key.name"        ~ nToLE(0x0_0000003U) ~ cast(ubyte[])"Key"));
		assert(val.canFind(nToLE(0x00000014U) ~ cast(ubyte[])"item.key.description" ~ nToLE(0x0_0000043U) ~ cast(ubyte[])"A rusty old-school golden key.\nYou don't know what door it unlocks."));
		assert(val.canFind(nToLE(0x00000004U) ~ cast(ubyte[])"grid" ~ nToLE(0x1_0000003U) ~
			nToLE(0x1_0000003U) ~
				nToLE(0x0_0000001U) ~ x"01" ~
				nToLE(0x0_0000001U) ~ x"02" ~
				nToLE(0x0_0000001U) ~ x"03" ~
			nToLE(0x1_0000003U) ~
				nToLE(0x0_0000001U) ~ x"04" ~
				nToLE(0x0_0000001U) ~ x"05" ~
				nToLE(0x0_0000001U) ~ x"06" ~
			nToLE(0x1_0000003U) ~
				nToLE(0x0_0000001U) ~ x"07" ~
				nToLE(0x0_0000001U) ~ x"08" ~
				nToLE(0x0_0000001U) ~ x"09"
		));
		assert(val.canFind(nToLE(0x00000006U) ~ cast(ubyte[])"-5 - 3" ~ nToLE(0x0_0000019U) ~ cast(ubyte[])"negative five minus three"));
		assert(val.canFind(nToLE(0x00000001U) ~ cast(ubyte[])"="      ~ nToLE(0x0_0000006U) ~ cast(ubyte[])"equals"));
		assert(val.canFind(nToLE(0x00000002U) ~ cast(ubyte[])":)"     ~ nToLE(0x0_0000006U) ~ cast(ubyte[])"smiley"));
	}
}

T parse(alias parser, T)(const ISLABinValue val, scope size_t i, return scope T fallback) =>
	val._type == ISLABinType.list && i < val._list.length ? parser(val._list[i]) : fallback;
T parseBin(alias parser, T)(const ISLABinValue val, scope size_t i, return scope T fallback) =>
	val._type == ISLABinType.list && i < val._list.length && val._list[i]._type == ISLABinType.bin  ? parser(val._list[i]._bin)  : fallback;
T parseList(alias parser, T)(const ISLABinValue val, scope size_t i, return scope T fallback) =>
	val._type == ISLABinType.list && i < val._list.length && val._list[i]._type == ISLABinType.list ? parser(val._list[i]._list) : fallback;
T parseMap(alias parser, T)(const ISLABinValue val, scope size_t i, return scope T fallback) =>
	val._type == ISLABinType.list && i < val._list.length && val._list[i]._type == ISLABinType.map  ? parser(val._list[i]._map)  : fallback;
unittest{
	const val = ISLABinValue([
		ISLABinValue("50"), ISLABinValue("-72"), ISLABinValue("4"), ISLABinValue("509"),
		ISLABinValue(["1", "2"]),
		ISLABinValue(["one": "1"]),
	]);
	assert(val.parse!(v => (cast(string)v.bin).to!int())(0,  9) == 50);
	assert(val.parse!(v => (cast(string)v.bin).to!int())(6, 12) == 12);
	assert(val.parseBin!(b => (cast(string)b).to!int())(0,  9) == 50);
	assert(val.parseBin!(b => (cast(string)b).to!int())(7, 12) == 12);
	import std.algorithm.iteration, std.array, std.typecons;
	assert(val.parseList!(l => l.map!(i => (cast(string)i.bin).to!int()).array)(4, [3]) == [1, 2]);
	assert(val.parseList!(l => l.map!(i => (cast(string)i.bin).to!int()).array)(8, [3]) == [3]);
	assert(val.parseMap!(m => m.byPair.map!(kv => tuple(kv[0], (cast(string)kv[1].bin).to!int())).assocArray)(5, [cast(immutable(void)[])"two": 2]) == [cast(immutable(void)[])"one": 1]);
	assert(val.parseMap!(m => m.byPair.map!(kv => tuple(kv[0], (cast(string)kv[1].bin).to!int())).assocArray)(9, [cast(immutable(void)[])"two": 2]) == [cast(immutable(void)[])"two": 2]);
}

T parse(alias parser, T)(const ISLABinValue val, scope const(void)[] key, return scope T fallback){
	if(val._type == ISLABinType.map){
		if(auto ret = key in val._map){
			return parser(*ret);
		}
	}
	return fallback;
}
T parseBin(alias parser, T)(const ISLABinValue val, scope const(void)[] key, return scope T fallback){
	if(val._type == ISLABinType.map){
		if(auto ret = key in val._map){
			if(ret._type == ISLABinType.bin)  return parser(ret._bin);
		}
	}
	return fallback;
}
T parseList(alias parser, T)(const ISLABinValue val, scope const(void)[] key, return scope T fallback){
	if(val._type == ISLABinType.map){
		if(auto ret = key in val._map){
			if(ret._type == ISLABinType.list) return parser(ret._list);
		}
	}
	return fallback;
}
T parseMap(alias parser, T)(const ISLABinValue val, scope const(void)[] key, return scope T fallback){
	if(val._type == ISLABinType.map){
		if(auto ret = key in val._map){
			if(ret._type == ISLABinType.map)  return parser(ret._map);
		}
	}
	return fallback;
}
unittest{
	const val = ISLABinValue([
		"two": ISLABinValue("2"), "four": ISLABinValue("4"), "six": ISLABinValue("6"),
		"123": ISLABinValue(["1", "2", "3"]), "twotwo": ISLABinValue(["two": "2"]),
	]);
	assert(val.parse!(v => (cast(string)v.bin).to!int())("two",   7) == 2);
	assert(val.parse!(v => (cast(string)v.bin).to!int())("eight", 8) == 8);
	assert(val.parseBin!(b => (cast(string)b).to!int())("two",   7) == 2);
	assert(val.parseBin!(b => (cast(string)b).to!int())("eight", 8) == 8);
	import std.algorithm.iteration, std.array, std.typecons;
	assert(val.parseList!(l => l.map!(i => (cast(string)i.bin).to!int()).array)("123", [4]) == [1, 2, 3]);
	assert(val.parseList!(l => l.map!(i => (cast(string)i.bin).to!int()).array)("321", [3, 2, 1]) == [3, 2, 1]);
	assert(val.parseMap!(m => m.byPair.map!(kv => tuple(cast(string)kv[0], (cast(string)kv[1].bin).to!int())).assocArray)("twotwo", ["four": 4]) == ["two": 2]);
	assert(val.parseMap!(m => m.byPair.map!(kv => tuple(cast(string)kv[0], (cast(string)kv[1].bin).to!int())).assocArray)("fourfour", ["four": 4]) == ["four": 4]);
}

private ISLABinValue decodeScope(scope ref immutable(ubyte)[] data) pure @safe{
	const lenType = data.read!(uint, Endian.littleEndian)();
	size_t len = lenType & ISLABinValue.maxLength;
	const type = cast(ISLABinType)(lenType >> ISLABinValue.lengthBits);
	switch(type){
		case ISLABinType.bin:
			if(len <= data.length){
				scope(exit) data = data[len..$];
				return ISLABinValue(bin: len ? data[0..len] : null);
			}else{
				throw new ISLADecodeOOBException("bin", len, data.length);
			}
		case ISLABinType.list:
			if(len * uint.sizeof <= data.length){
				auto list = new ISLABinValue[](len);
				foreach(ref item; list)
					item = data.decodeScope();
				
				return ISLABinValue(list: len ? list : null);
			}else{
				throw new ISLADecodeOOBException("list", len, data.length);
			}
		case ISLABinType.map:
			if(len * uint.sizeof * 2U <= data.length){
				ISLABinValue[immutable(void)[]] map;
				foreach(_; 0..len){
					const keyLen = data.read!(uint, Endian.littleEndian)();
					if(keyLen <= data.length){
						auto key = data[0..keyLen];
						data = data[keyLen..$];
						map[key] = data.decodeScope();
					}else{
						throw new ISLADecodeOOBException("map key", keyLen, data.length);
					}
				}
				return ISLABinValue(map: map);
			}else{
				throw new ISLADecodeOOBException("map", len, data.length);
			}
		default:
			throw new ISLAException("Invalid type: "~type.to!string());
	}
}

/**
Decodes a series of bytes representing data in the ISLA binary format.

Params:
	data = A range of `void`s.
*/
ISLABinValue decode(scope immutable(void)[] data) pure @safe{
	if(data.length == 0) throw new ISLAException("Empty array provided");
	
	if(data[0..header.length] != header) throw new ISLAException("Bad header: "~data[0..header.length].toHexString());
	data = data[header.length..$];
	
	auto ubyteArr = cast(immutable(ubyte)[])data;
	return ubyteArr.decodeScope();
}
unittest{
	ISLABinValue val;
	alias nToLE = nativeToLittleEndian;
	val = isla.bin.decode((header ~
		//      T LLLLLLL (4-bit type; 28-bit length)
		nToLE(0x1_0000004U) ~ //type:1 (list), length:4
		nToLE(0x0_0000002U) ~ cast(ubyte[])";)" ~ //type:0 (bin), length:2 bytes
		nToLE(0x0_0000002U) ~ cast(ubyte[])":3" ~ //type:0 (bin), length:2 bytes
		nToLE(0x0_0000000U) ~                     //type:0 (bin), length:0 bytes (i.e. null)
		nToLE(0x0_0000001U) ~ cast(ubyte[])":"    //type:0 (bin), length:1 byte
	).idup());
	assert(val[0] == ";)");
	assert(val[1] == ":3");
	assert(val[2] is ISLABinValue(bin: null));
	assert(val[3] == ":");
	
	val = isla.bin.decode((header ~
		nToLE(0x2_0000004) ~ //type:2 (map), length:4
		nToLE(0x00000002) ~ cast(ubyte[])"-3"         ~ nToLE(0x0_000000B) ~ cast(ubyte[])"Minus three" ~
		nToLE(0x00000006) ~ cast(ubyte[])"e=mc^2"     ~ nToLE(0x0_0000019) ~ cast(ubyte[])"Mass–energy equivalence" ~
		nToLE(0x0000000D) ~ cast(ubyte[])`¯\_(ツ)_/¯` ~ nToLE(0x0_0000007) ~ cast(ubyte[])"a shrug" ~
		nToLE(0x00000002) ~ cast(ubyte[])":)"         ~ nToLE(0x0_0000008) ~ cast(ubyte[])"a smiley"
	).idup());
	assert("-3" in val);
	assert("e=mc^2" in val);
	assert(`¯\_(ツ)_/¯` in val);
	assert(":)" in val);
	assert(":(" !in val);
	assert(null !in val);
	
	val = isla.bin.decode((header ~
		nToLE(0x2_0000001) ~ //type:2 (map), length:1
		nToLE(0x00000005) ~ cast(ubyte[])"Quote" ~ nToLE(0x0_000003F) ~ cast(ubyte[])"He engraved on it the words:\n\"And this, too, shall pass away.\n\""
	).idup());
	assert(val["Quote"] == "He engraved on it the words:\n\"And this, too, shall pass away.\n\"");
	val = isla.bin.decode((header ~ nToLE(0x2_0000007U) ~ //header; type:2 (map), length:7
		nToLE(0x00000006U) ~ cast(ubyte[])"health" ~ nToLE(0x0_0000001U) ~ x"64" ~ //key length:6; key:"health"; type:0 (bin),  length:1; value:100
		nToLE(0x00000005U) ~ cast(ubyte[])"items"  ~ nToLE(0x1_0000003U) ~         //key length:5; key:"items";  type:1 (list), length:3
			nToLE(0x0_0000005) ~ cast(ubyte[])"apple" ~ //type:0 (bin), length:5; value:"apple"
			nToLE(0x0_0000005) ~ cast(ubyte[])"apple" ~ //et cetera
			nToLE(0x0_0000003) ~ cast(ubyte[])"key" ~
		nToLE(0x0000000CU) ~ cast(ubyte[])"translations"  ~ nToLE(0x2_0000001U) ~
			nToLE(0x00000005U) ~ cast(ubyte[])"en-UK"  ~ nToLE(0x2_0000004U) ~
		nToLE(0x0000000FU) ~ cast(ubyte[])"item.apple.name"        ~ nToLE(0x0_0000005U) ~ cast(ubyte[])"Apple" ~
		nToLE(0x00000016U) ~ cast(ubyte[])"item.apple.description" ~ nToLE(0x0_000004AU) ~ cast(ubyte[])"A shiny, ripe, red apple that\nfell from a nearby tree.\nIt looks delicious!" ~
		nToLE(0x0000000DU) ~ cast(ubyte[])"item.key.name"        ~ nToLE(0x0_0000003U) ~ cast(ubyte[])"Key" ~
		nToLE(0x00000014U) ~ cast(ubyte[])"item.key.description" ~ nToLE(0x0_0000043U) ~ cast(ubyte[])"A rusty old-school golden key.\nYou don't know what door it unlocks." ~
		nToLE(0x00000004U) ~ cast(ubyte[])"grid" ~ nToLE(0x1_0000003U) ~
			nToLE(0x1_0000003U) ~
				nToLE(0x0_0000001U) ~ x"01" ~
				nToLE(0x0_0000001U) ~ x"02" ~
				nToLE(0x0_0000001U) ~ x"03" ~
			nToLE(0x1_0000003U) ~
				nToLE(0x0_0000001U) ~ x"04" ~
				nToLE(0x0_0000001U) ~ x"05" ~
				nToLE(0x0_0000001U) ~ x"06" ~
			nToLE(0x1_0000003U) ~
				nToLE(0x0_0000001U) ~ x"07" ~
				nToLE(0x0_0000001U) ~ x"08" ~
				nToLE(0x0_0000001U) ~ x"09" ~
		nToLE(0x00000006U) ~ cast(ubyte[])"-5 - 3" ~ nToLE(0x0_0000019U) ~ cast(ubyte[])"negative five minus three" ~
		nToLE(0x00000001U) ~ cast(ubyte[])"="      ~ nToLE(0x0_0000006U) ~ cast(ubyte[])"equals" ~
		nToLE(0x00000002U) ~ cast(ubyte[])":)"     ~ nToLE(0x0_0000006U) ~ cast(ubyte[])"smiley"
	).idup());
	assert(val["health"] == ISLABinValue(x"64"));
	assert(val["health"] == x"64");
	assert(val["items"][1] == "apple");
	assert(val["translations"]["en-UK"]["item.apple.name"] == "Apple");
	assert(val["translations"]["en-UK"]["item.key.description"] == "A rusty old-school golden key.\nYou don't know what door it unlocks.");
	assert(val["grid"][1][1] == x"05");
	assert(val["-5 - 3"] == "negative five minus three");
	assert(val["="] == "equals");
	assert(val[":)"] == "smiley");
}
