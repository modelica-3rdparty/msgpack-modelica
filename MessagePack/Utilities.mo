within MessagePack;

package Utilities

  package Stream

    class Stream
      extends ExternalObject;
      function constructor
        input String file := "" "Output file or \"\" for an in-memory string accessible using get()";
        output Stream ss;
      external "C" ss=msgpack_modelica_new_stream(file) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
      end constructor;
      function destructor
        input Stream ss;
      external "C" msgpack_modelica_free_stream(ss) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
      end destructor;
    end Stream;

    function get "Only works for in-memory streams"
      // Make this a part of the Stream class once the Modelica Spec allows it...
      input Stream ss;
      output String str;
    external "C" str=msgpack_modelica_stream_get(ss) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
    end get;

    function append
      // Make this a part of the Stream class once the Modelica Spec allows it...
      input Stream ss;
      input String str;
    external "C" msgpack_modelica_stream_append(ss,str) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
    end append;

  end Stream;

  function deserializeFileToFile
    input String inBinaryFile;
    input String outTextFile;
    input String separator := "\n";
  protected
    Unpack.Deserializer deserializer = Unpack.Deserializer(inBinaryFile);
    Stream.Stream ss = Stream.Stream(outTextFile);
    Boolean success := true;
    Integer offset := 0;
  algorithm
    while success loop
      (offset,success) := Unpack.toStream(deserializer,ss,offset);
      if success then
        Stream.append(ss,separator);
      end if;
    end while;
  end deserializeFileToFile;

end Utilities;
