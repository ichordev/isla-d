/+
+            Copyright 2023 – 2024 Aya Partridge
+ Distributed under the Boost Software License, Version 1.0.
+     (See accompanying file LICENSE_1_0.txt or copy at
+           http://www.boost.org/LICENSE_1_0.txt)
+/
module isla.common;

import std.conv;

class ISLAException: Exception{
	 this(string msg, string file=__FILE__, size_t line=__LINE__) nothrow pure @safe{
		super(msg, file, line);
	}
}
class ISLAEncodeTooLongException: ISLAException{
	 this(string desc, size_t length, size_t maxLength, string file=__FILE__, size_t line=__LINE__) nothrow pure @safe{
	 	super("Tried to encode "~desc~" with length "~length.to!string()~". Must be at most "~maxLength.to!string(), file, line);
	}
}
class ISLADecodeOOBException: ISLAException{
	 this(string desc, size_t length, size_t bytesLeft, string file=__FILE__, size_t line=__LINE__) nothrow pure @safe{
	 	super("Tried to decode "~desc~" with length "~length.to!string()~", but only "~bytesLeft.to!string()~" bytes remain", file, line);
	}
}
