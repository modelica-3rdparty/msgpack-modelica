within MessagePack;

package Unpack

class Deserializer
  extends ExternalObject;
  function constructor
    input String file;
    output Deserializer deserializer;
  external "C" deserializer=msgpack_modelica_new_deserialiser(file) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
  end constructor;
  function destructor
    input Deserializer deserializer;
  external "C" msgpack_modelica_free_deserialiser(deserializer) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
  end destructor;
end Deserializer;

function next
  input Deserializer deserializer;
  input Integer offset;
  output Boolean success;
  output Integer newoffset;
external "C" success=msgpack_modelica_unpack_next(deserializer,offset,newoffset) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
end next;

function toStream
  input Deserializer deserializer;
  input Utilities.Stream.Stream ss;
  input Integer offset;
  output Integer newoffset;
  output Boolean success;
external "C" success=msgpack_modelica_unpack_next_to_stream(deserializer,ss,offset,newoffset) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
end toStream;

function integer
  input Deserializer deserializer;
  input Integer offset;
  output Integer res;
  output Integer newoffset;
  output Boolean success;
external "C" res=msgpack_modelica_unpack_int(deserializer,offset,newoffset,success) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
end integer;

function string
  input Deserializer deserializer;
  input Integer offset;
  output String res;
  output Integer newoffset;
  output Boolean success;
external "C" res=msgpack_modelica_unpack_string(deserializer,offset,newoffset,success) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
end string;

function get_integer // TODO: Create package MessagePack.Object and move this there
  input Deserializer deserializer;
  output Integer res;
external "C" res=msgpack_modelica_get_unpacked_int(deserializer) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
end get_integer;

end Unpack;
