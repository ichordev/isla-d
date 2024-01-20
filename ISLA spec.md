# Inline Serialisation for Lesbian Applications specification
- Version 1.0 (2023-07-28) by Aya Partridge
- [FUTURE SPEC. VERSIONS/DATES/AUTHORS GO HERE]

ISLA stores a hierarchy of strings. Encoding and decoding of the strings into other formats (e.g. numbers, dates, colours, etc.) must be performed separately by the user.

ISLA files use the extension `.ISLA`. If (and only if) file extensions are limited to 3 letters, then `.ILA` is permissible.

ISLA files should always be encoded in UTF-8, or ASCII.

Lines in ISLA files are broken by a single line feed codepoint (U+000A).

The first line of an ISLA file must be the string `ISLA` followed directly by the ISLA specification version number, which in this case is `1`.

**Example:**
```isla
ISLA1
```

Lines that match any of the following cases will be skipped by the parser:
- Empty lines.
- Lines with a number of horizontal tabulator codepoints (U+0009) corresponding to the current *nesting level*.
- Lines starting with a number of horizontal tabulator codepoints (U+0009) less than or equal to the current *nesting level*, followed by a semicolon and an optional arbitrary series of non-line-breaking codepoints. (i.e. a comment)

**Example:**
```isla
ISLA1

	
	;This is a comment!
     
   ;Another comment :)
```

The number of horizontal tabulators (U+0009) at the start of a line indicates the current *nesting level*.

When a new *scope* is created, the *nesting level* on the next line must be increased by 1.

Decreases in *nesting level* on subsequent lines indicate the end of a corresponding number of *scopes*.

A *scope* is either a [*list*](#lists) or a [*map*](#maps).

## Lists
A *list* is a series of values, each value can be numerically indexed sequentially.

Each line in a *list* starts with a hyphen-minus (`-`) followed by either:
- a value;
- a reverse solidus followed by a colon (`\:`) a value with only a colon; or
- a colon (`:`) to create a new *scope* on the next line.

**Example:**
```
ISLA1
-first item
-second item
-:
	-nested list item one!
	-nested list item two!
-:fourth item, starts with a colon
-\:
```
**Example parses to:**
```
,----------------------------------,
|first item                        |
|----------------------------------|
|second item                       |
|----------------------------------|
| ,----------------------,         |
| |nested list item one! |         |
| |----------------------|         |
| |nested list item two! |         |
| '----------------------'         |
|----------------------------------|
|:fourth item, starts with a colon |
|----------------------------------|
|:                                 |
'----------------------------------'
```

## Maps
A *map* is a series of key-value pairs, each value can be indexed by the key it's paired with.

Each starts with an arbitrary series of codepoints—excluding hyphen-minuses (`-`) for the first line, and also equals signs (`=`), and colons (`:`)—which represent a key in the *map*. Followed by either:
- an equals sign (`=`) and a value; or
- a colon (`:`) to create a new *scope* on the next line.

A reverse solidus followed by an equals sign, a colon, or a hyphen-minus (`\=`, `\:`, or `\-`) can be used to represent a literal equals sign, colon, or hyphen-minus in a key.

**Example:**
```isla
ISLA1
Name=Jill
Best friend=Jim
Spouse=Sam
Phonebook:
	Jim=888 44 747 47
	Sam=888 11 915 55
	Emergency=0118 999 88199 9119 725 3
e\=mc^2=Mass–energy equivalence
¯\_(ツ)_/¯=a shrug
\:)=a smiley
```
**Example parses to:**
```
,----------------+-----------------------------------------,
|Name            |Jill                                     |
|----------------+-----------------------------------------|
|Best friend     |Jim                                      |
|----------------+-----------------------------------------|
|Spouse          |Sam                                      |
|----------------+-----------------------------------------|
|Phonebook       | ,----------+--------------------------, |
|                | |Jim       |888 44 747 47             | |
|                | |----------+--------------------------| |
|                | |Sam       |888 11 915 55             | |
|                | |----------+--------------------------| |
|                | |Emergency |0118 999 88199 9119 725 3 | |
|                | '----------+--------------------------' |
|----------------+-----------------------------------------|
|e=mc^2          |Mass–energy equivalence                  |
|----------------+-----------------------------------------|
|¯\_(ツ)_/¯      |a shrug                                  |
|----------------+-----------------------------------------|
|:)              |a smiley                                 |
'----------------+-----------------------------------------'
```

If a value starts with a double quotation mark (`"`) then a line-break should follow, which will be the start of a [multi-line value](#multi-line-values).
A reverse solidus followed by a double quotation mark (`\"`) at the start of a value represents a literal double quotation mark (`"`).

## Multi-line values

A multi-line value has no nesting level, and is represented by an arbitrary number of lines with any contents until a line containing only a double quotation mark (`"`) is found.

A line with only a reverse solidus followed by a double quotation mark (`\"`) in a multi-line value represents a literal double quotation mark (`"`).

**Example:**
```isla
ISLA1
Paragraph="
Lorem ipsum dolor sit amet,
consectetur adipiscing elit,
sed do eiusmod tempor incididunt
ut labore et dolore magna aliqua.
"
Quote="
He engraved on it the words:
"And this, too, shall pass away.
\"
"
```
**Example parses to:**
```
,----------+----------------------------------,
|Paragraph |Lorem ipsum dolor sit amet,       |
|          |consectetur adipiscing elit,      |
|          |sed do eiusmod tempor incididunt  |
|          |ut labore et dolore magna aliqua. |
|----------+----------------------------------|
|Quote     |He engraved on it the words:      |
|          |"And this, too, shall pass away." |
'----------+----------------------------------'
```

**Example:**
```isla
ISLA1
health=100
items:
	-apple
	-apple
	-key
translations:
	en-UK:
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
	-:
		-7
		-8
		-9
```
**Example parses to:**
```
,-------------+----------------------------------------------------------------------------,
|health       |100                                                                         |
|-------------+----------------------------------------------------------------------------|
|             | ,----------,                                                               |
|             | |apple     |                                                               |
|             | |----------|                                                               |
|items        | |apple     |                                                               |
|             | |----------|                                                               |
|             | |key       |                                                               |
|             | '----------'                                                               |
|-------------+----------------------------------------------------------------------------|
|             | ,------+-----------------------------------------------------------------, |
|             | |      | ,-----------------------+-------------------------------------, | |
|             | |      | |item.apple.name        |Apple                                | | |
|             | |      | |-----------------------+-------------------------------------| | |
|             | |      | |item.apple.description |A shiny, ripe, red apple that        | | |
|             | |      | |                       |fell from a nearby tree.             | | |
|translations | |en-UK | |                       |It looks delicious!                  | | |
|             | |      | |-----------------------+-------------------------------------| | |
|             | |      | |item.key.name          |Key                                  | | |
|             | |      | |-----------------------+-------------------------------------| | |
|             | |      | |item.key.description   |A rusty old-school golden key.       | | |
|             | |      | |                       |You don't know what door it unlocks. | | |
|             | |      | '-----------------------+-------------------------------------' | |
|             | '------+-----------------------------------------------------------------' |
|-------------+----------------------------------------------------------------------------|
|             | ,----------,                                                               |
|             | | ,------, |                                                               |
|             | | |1     | |                                                               |
|             | | |------| |                                                               |
|             | | |2     | |                                                               |
|             | | |------| |                                                               |
|             | | |3     | |                                                               |
|             | | '------' |                                                               |
|             | |----------|                                                               |
|             | | ,------, |                                                               |
|             | | |4     | |                                                               |
|             | | |------| |                                                               |
|grid         | | |5     | |                                                               |
|             | | |------| |                                                               |
|             | | |6     | |                                                               |
|             | | '------' |                                                               |
|             | |----------|                                                               |
|             | | ,------, |                                                               |
|             | | |7     | |                                                               |
|             | | |------| |                                                               |
|             | | |8     | |                                                               |
|             | | |------| |                                                               |
|             | | |9     | |                                                               |
|             | | '------' |                                                               |
|             | '----------'                                                               |
'-------------+----------------------------------------------------------------------------'
```
