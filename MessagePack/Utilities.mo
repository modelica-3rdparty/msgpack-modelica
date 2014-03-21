within MessagePack;

package Utilities

  package StringStream

    class StringStream
      extends ExternalObject;
      function constructor
        output StringStream ss;
      external "C" ss=msgpack_modelica_new_stringstream() annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
      end constructor;
      function destructor
        input StringStream ss;
      external "C" msgpack_modelica_free_stringstream(ss) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
      end destructor;
    end StringStream;

    function get
      // Make this a part of the StringStream class once the Modelica Spec allows it...
      input StringStream ss;
      output String str;
    external "C" str=msgpack_modelica_stringstream_get(ss) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
    end get;

    function append
      // Make this a part of the StringStream class once the Modelica Spec allows it...
      input StringStream ss;
      input String str;
    external "C" msgpack_modelica_stringstream_append(ss,str) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
    end append;

  end StringStream;

end Utilities;
