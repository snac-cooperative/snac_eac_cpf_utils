#!/bin/bash
export CLASSPATH=$HOME/bin/saxon9he.jar:$CLASSPATH
java net.sf.saxon.Transform ${1+"$@"}
