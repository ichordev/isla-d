/+
+            Copyright 2023 – 2024 Aya Partridge
+ Distributed under the Boost Software License, Version 1.0.
+     (See accompanying file LICENSE_1_0.txt or copy at
+           http://www.boost.org/LICENSE_1_0.txt)
+/
module isla.common;

import std.format;

class ISLAException: Exception{
	 this(string msg, string file=__FILE__, size_t line=__LINE__) nothrow pure @safe{
		super(msg, file, line);
	}
}

class ISLAListIndexException: ISLAException{
	 this(size_t index, size_t length, string file=__FILE__, size_t line=__LINE__) nothrow pure @safe{
	 	string msg;
	 	try msg = format!"Index [%s] is out of bounds for list of length %s"(index, length);
	 	catch(Exception ex){}
		super(msg, file, line);
	}
}
class ISLAMapKeyException: ISLAException{
	 this(string key, string file=__FILE__, size_t line=__LINE__) nothrow pure @safe{
	 	string msg;
	 	try msg = format!"Key [%s] not found in map"(key);
	 	catch(Exception ex){}
		super(msg, file, line);
	}
}

class ISLAEncodeTooLongException: ISLAException{
	 this(string desc, size_t length, size_t maxLength, string file=__FILE__, size_t line=__LINE__) nothrow pure @safe{
	 	string msg;
	 	try msg = format!"Tried to encode %s with length %s. Must be at most %s"(desc, length, maxLength);
	 	catch(Exception ex){}
		super(msg, file, line);
	}
}
class ISLADecodeOOBException: ISLAException{
	 this(string desc, size_t length, size_t bytesLeft, string file=__FILE__, size_t line=__LINE__) nothrow pure @safe{
	 	string msg;
	 	try msg = format!"Tried to decode %s with length %s, but only %s bytes remain"(desc, length, bytesLeft);
	 	catch(Exception ex){}
		super(msg, file, line);
	}
}
