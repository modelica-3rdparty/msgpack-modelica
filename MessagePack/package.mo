/*
Copyright (c) 2014, Martin Sjölund
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

encapsulated package MessagePack

class SimpleBuffer
  extends ExternalObject;

  function constructor
    output SimpleBuffer buf;
  external "C" buf = msgpack_sbuffer_new() annotation(Include="#include <msgpack-modelica.h>", Library="msgpackc");
  end constructor;

  function destructor
    input SimpleBuffer buf;
  external "C" msgpack_sbuffer_free(buf) annotation(Include="#include <msgpack-modelica.h>", Library="msgpackc");
  end destructor;

end SimpleBuffer;

class Packer
  extends ExternalObject;

  function constructor
    input SimpleBuffer buf;
    output Packer packer;
  external "C" packer = msgpack_modelica_packer_new_sbuffer(buf) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
  end constructor;

  function destructor
    input Packer packer;
  external "C" msgpack_packer_free(packer) annotation(Include="#include <msgpack-modelica.h>", Library="msgpackc");
  end destructor;

end Packer;

function pack_double
  input Packer packer;
  input Real dbl;
  output Boolean result;
  external "C" result=msgpack_pack_double(packer,dbl) annotation(Include="#include <msgpack-modelica.h>", Library="msgpackc");
end pack_double;

function pack_integer
  input Packer packer;
  input Integer i;
  output Boolean result;
  external "C" result=msgpack_pack_int(packer,i) annotation(Include="#include <msgpack-modelica.h>", Library="msgpackc");
end pack_integer;

function pack_bool
  input Packer packer;
  input Boolean bool;
  output Boolean result;
protected
  function msgpack_pack_true
    input Packer packer;
    output Boolean result;
    external "C" annotation(Include="#include <msgpack-modelica.h>", Library="msgpackc");
  end msgpack_pack_true;
  function msgpack_pack_false
    input Packer packer;
    output Boolean result;
    external "C" annotation(Include="#include <msgpack-modelica.h>", Library="msgpackc");
  end msgpack_pack_false;
algorithm
  result := if bool then msgpack_pack_true(packer) else msgpack_pack_false(packer);
end pack_bool;

function pack_array
  input Packer packer;
  input Integer len;
  output Boolean result;
external "C" result=msgpack_modelica_pack_array(packer,len) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
end pack_array;

function pack_map
  input Packer packer;
  input Integer len;
  output Boolean result;
external "C" result=msgpack_modelica_pack_map(packer,len) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
end pack_map;

function pack_string
  input Packer packer;
  input String str;
  output Boolean result;
  external "C" result=msgpack_modelica_pack_string(packer,str) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
end pack_string;

function to_file
  input SimpleBuffer sbuffer;
  input String file;
  external "C" omc_sbuffer_to_file(sbuffer,file) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
end to_file;

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

function unpack_next
  input Deserializer deserializer;
  input Integer offset;
external "C" success=msgpack_modelica_unpack_next(deserializer,offset,newoffset) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
end unpack_next;

function unpack_any_to_stringstream
  input Deserializer deserializer;
  input StringStream ss;
  input Integer offset;
  output Integer newoffset;
  output Boolean success;
external "C" success=msgpack_modelica_unpack_any_to_stringstream(deserializer,ss,offset,newoffset) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
end unpack_any_to_stringstream;

function unpack_int
  input Deserializer deserializer;
  input Integer offset;
  output Integer res;
  output Integer newoffset;
  output Boolean success;
external "C" res=msgpack_modelica_unpack_int(deserializer,offset,newoffset,success) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
end unpack_int;

function unpack_string
  input Deserializer deserializer;
  input Integer offset;
  output String res;
  output Integer newoffset;
  output Boolean success;
external "C" res=msgpack_modelica_unpack_string(deserializer,offset,newoffset,success) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
end unpack_string;

function get_unpacked_int
  input Deserializer deserializer;
  output Integer res;
external "C" res=msgpack_modelica_get_unpacked_int(deserializer) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
end get_unpacked_int;

function stringstream_get
  input StringStream ss;
  output String str;
external "C" str=msgpack_modelica_stringstream_get(ss) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
end stringstream_get;

function stringstream_append
  input StringStream ss;
  input String str;
external "C" msgpack_modelica_stringstream_append(ss,str) annotation(Include="#include <msgpack-modelica.h>",  Library={"msgpackc"});
end stringstream_append;

end MessagePack;
