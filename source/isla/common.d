/+
+            Copyright 2023 – 2024 Aya Partridge
+ Distributed under the Boost Software License, Version 1.0.
+     (See accompanying file LICENSE_1_0.txt or copy at
+           http://www.boost.org/LICENSE_1_0.txt)
+/
module isla.common;

class ISLAException: Exception{
	 this(string msg, string file=__FILE__, size_t line=__LINE__) nothrow pure @safe{
		super(msg, file, line);
	}
}