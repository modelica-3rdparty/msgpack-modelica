within MessagePack;

package UsersGuide

package License
annotation(Documentation(info="<html>
<p>Copyright (c) 2014, Martin Sj&ouml;lund<br />
All rights reserved.</p>

<p>Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:</p>

<ul>
<li>Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.</li>
<li>Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.</li>
</ul>

<p>THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.</p>

</html>"));
end License;

annotation(Documentation(info="<html>
<p>This implementation uses <a href=\"https://github.com/msgpack/msgpack-c\">msgpack-c</a> together with external objects and external \"C\" functions (Modelica cannot represent binary objects, so everything has to be hidden inside external functions).</p>
<p>You will need to install msgpack-c in order to use this Modelica package (msgpack.h and libmsgpack-c.*).</p>
<p>The external C code of this package is inserted using Include annotations, so there should be no need to compile any libraries prior to using the package.</p>
</html>"));
end UsersGuide;
