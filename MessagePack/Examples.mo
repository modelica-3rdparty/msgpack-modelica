within MessagePack;

package Examples

model TestCreateAndReadFile
protected
  function createFile
    input String file;
  protected
    import MessagePack.Pack;
    Pack.SimpleBuffer.SimpleBuffer sbuffer = Pack.SimpleBuffer.SimpleBuffer();
    Pack.Packer packer = Pack.Packer(sbuffer);
  algorithm
    Pack.integer(packer,-65538);
    Pack.string(packer,"Modelica");
    Pack.map(packer, 1);
    Pack.double(packer,1.0);
    Pack.bool(packer,true);
    Pack.sequence(packer, 2);
    Pack.integer(packer,65538);
    Pack.double(packer,2.0);
    Pack.bool(packer,false);
    Pack.string(packer,"Modelica");
    Pack.SimpleBuffer.writeFile(sbuffer,file);
  end createFile;

  function readFile
    input String file;
    output String result;
  protected
    import MessagePack.Utilities.Stream;
    import MessagePack.Unpack;
    Unpack.Deserializer deserializer = Unpack.Deserializer(file);
    Stream.Stream ss = Stream.Stream();
    Integer offset = 0, i;
    String s;
    Boolean success;
  algorithm
    (i,offset) := Unpack.integer(deserializer,offset);
    (s,offset) := Unpack.string(deserializer,offset);
    offset := Unpack.toStream(deserializer,ss,offset);
    success := true;
    while success loop
      (offset,success) := Unpack.toStream(deserializer,ss,offset);
      Stream.append(ss,"\n");
    end while;
    result := Stream.get(ss);
  end readFile;

  function createAndReadFile
    input String filename;
    output String msg;
  protected
    String res;
  algorithm
    createFile(filename);
    res := readFile(filename);
    msg := "msgpack data from file " + filename + ": " + readFile(filename);
    assert(res=="{1.000000=>true}[65538, 2.000000]\nfalse\n\"Modelica\"\n\n", "Failed to read back "+msg);
    msg := "Succeeded to write and read "+msg;
  end createAndReadFile;
  Real dummy=1 "Need at least 1 variable to make OpenModelica happy";
initial algorithm
  terminate(createAndReadFile("msgpack.out"));
  annotation(experiment(StopTime=1.0), Documentation(info="
<html>
<p>This model tests that it is possible to create (serialize) a file
encoded in MessagePack format, and verifies that it is possible to read
back this data.</p>
</html>
")
);
end TestCreateAndReadFile;

end Examples;
