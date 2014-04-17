#! /usr/bin/python
import sys
from TOSSIM import *

t = Tossim([])

t.addChannel("Boot", sys.stdout);

t.getNode(1).bootAtTime(100001);
t.getNode(2).bootAtTime(800002);

for i in range(100):
    t.runNextEvent()
