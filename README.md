# ISLA-D
A simple & usable library for the ISLA serialisation format in D.

## ISLA format
ISLA comes in two flavours:
- ISLA text: based on UTF-8 strings, human-readable, easy to edit, has comments, similar to YAML. See `example_dub.isla` for an example of the syntax.
- ISLA binary: based on raw binary data, much faster to encode/decode, suitable for applications that need to save binary data.

Both varieties of ISLA recognise 3 distinct types:
- str/bin: a `string` for ISLA text, or an `immutable(void)[]` for ISLA binary. Further decoding is to be done by the user based on their needs.
- list: an ordered list of values.
- map: a key-value map. Keys are always str/bin.

## Examples
ISLA text:
```d
import isla.txt;

void loadSaveData(ref Hero hero){
	import std.file: readText;
	import std.string: lineSplitter;
	//read an ISLA text file
	string saveFileContent = readText("savefile.isla");
	//decode the text into an ISLAValue
	ISLAValue saveData = isla.txt.decode(lineSplitter(saveFileContent));
	
	import std.conv: to;
	try{
		//get "hp", converted to int. If "hp" is not found, default to `100`
		hero.health = saveData.get("hp", to!int, 100);
		hero.level = saveData.get("level", to!int, 1);
		
		//get item 0 from "pos", converted to double. If "pos" is not found, an ISLAMapKeyException will be thrown
		hero.x = saveData["pos"][0].to!double();
		hero.y = saveData["pos"][1].to!double();
	}catch(ISLAException ex){
		//handle the exception...
		quit(error: ex.toString());
	}
}
```

ISLA binary:
```d
import isla.bin;

void loadSaveData(ref Hero hero){
	import std.file: read;
	//read an ISLA binary file
	string saveFileContent = read("savefile.isla");
	//decode the binary data into an ISLABinValue
	ISLABinValue saveData = isla.bin.decode(saveFileContent);
	
	import std.bitmanip: peek;
	auto read(T)(const(void)[] x) => peek!T(cast(const(ubyte)[])x);
	try{
		//get "hp", converted to int. If "hp" is not found, default to `100`
		hero.health = saveData.get("hp", read!int, 100);
		//get "level", converted to int. If "level" is not found, default to `1`
		hero.level = saveData.get("level", read!int, 1);
		
		//get item 0 from "pos", converted to double. If "pos" is not found, an ISLAMapKeyException will be thrown
		hero.x = saveData["pos"][0].read!double();
		hero.y = saveData["pos"][1].read!double();
	}catch(ISLAException ex){
		//handle any exceptions...
		quit(error: ex.toString());
	}
}
```
