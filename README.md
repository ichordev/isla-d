# ISLA-D
A simple & usable library for the ISLA serialisation formats in D.

## ISLA
Comes in two flavours:
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
	string saveFileContent = readText("savefile.isla"); //read an ISLA text file
	ISLAValue saveData = isla.txt.decode(lineSplitter(saveFileContent)); //decode the text into an ISLAValue
	
	import std.conv: to;
	try{
		hero.health = saveData.get("hp", to!int, 100); //get "hp", converted to int. If "hp" is not found, default to `100`
		hero.level = saveData.get("level", to!int, 1);
		hero.x = saveData["pos"][0].to!double(); //get item 0 from "pos", converted to double. If "pos" is not found, an ISLAException will be thrown.
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
	string saveFileContent = read("savefile.isla"); //read an ISLA binary file
	ISLABinValue saveData = isla.bin.decode(saveFileContent); //decode the binary data into an ISLABinValue
	
	import std.bitmanip: peek;
	try{
		auto read(T)(const(void)[] x) => peek!T(cast(const(ubyte)[])x);
		hero.health = saveData.get("hp", read!int, 100); //get "hp", converted to int. If "hp" is not found, default to `100`
		hero.level = saveData.get("level", read!int, 1); //get "level", converted to int. If "level" is not found, default to `1`
		hero.x = saveData["pos"][0].read!double(); //If "pos" is not found, an ISLAMapKeyException will be thrown.
		hero.y = saveData["pos"][1].read!double();
	}catch(ISLAException ex){
		//handle any exceptions...
		quit(error: ex.toString());
	}
}
```