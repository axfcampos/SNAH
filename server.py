#! /usr/bin/python

# ASE Project 2013/2014 - Instituto Superior Tecnico
# @author - Alexandre Filipe Campos - 66354

import sys
import math
import time
from TOSSIM import *
from threading import Thread
from PingMsg import *


def main(argv):


    #vars
    global n_nodes, t, r
    MAX_NODES = 10000
    nodeList = []

    t = Tossim([])
    what = t.mac()
    r = t.radio()

    # === Welcome
    print "ASE Project 2013/2014 by Alexandre Campos"
    print "+++ "

    # === add debug and log channels ===
    t.addChannel("Boot", sys.stdout)


    # === prompt for how many motes ===
    prompt_n_nodes(MAX_NODES)

    # === add topology ===
    f = open("topo.txt", "r")
    print "=== Creating Network topology"
    for l in f:
        s = l.split()
        r.add(int(s[0]), int(s[1]), float(s[2]))
    print "+++ Network topology set"



    # ===create nodes ===
    for x in range(0, n_nodes):
        print "=== Creating and starting node %d " % x
        m = t.getNode(x)
        nodeList.append(m)
        m.turnOn()
        #m.bootAtTime((31 + t.ticksPerSecond() / 10) * x + 1)
        print " - its on!"
        # add noise to node
        f = open("noise.txt", "r")
        for l in f:
            s = l.strip()
            if s:
                m.addNoiseTraceReading(int(s))
        m.createNoiseModel()
        print " - added noise "
        print "+++ Node %d start complete! " % x


    # === start prompt for user commands ===
    prompt_thr = Thread(target=command_prompt, args=())
    prompt_thr.start()

    #run next event 4ever
    print "still running"
    while 1:
        time.sleep(0.001) #slow things a bit
        t.runNextEvent() #run next event


def prompt_n_nodes(max_nodes):

    try:
        global n_nodes
        n_nodes = int(raw_input("Insert number of nodes in the network (max %d):" % max_nodes))
        if n_nodes < 1:
            print "Not a valid input. Try again!"
            prompt_n_nodes(max_nodes);
        print "Creating network of %d nodes!" % n_nodes
    except ValueError:
        print "Not a valid input. Try again!"
        prompt_n_nodes(max_nodes)

def command_prompt():
    #do nothing
    print "=== Command prompt initiated!"
    print "=== Type \'h\' for command list"

    while 1:
        sys.stdout.write('> ')
        line = sys.stdin.readline()
        cmd = line.split()

        if len(cmd) == 0:
            continue
        elif cmd[0] == "ping":
            ping()
        elif cmd[0] == "exit":
            print "leaving . . . . goodbye!"
            break
        elif cmd[0] == "h":
            print "- 'h' for help"
            print "- 'ping' to ping all nodes"
            print "- 'exit' to exit"
        else:
            print "wrong input. type 'h' for help"


def ping():
    msg = PingMsg()
    msg.set_number(7)
    pkt = t.newPacket()
    pkt.setData(msg.data)
    pkt.setType(msg.get_amType())
    pkt.setDestination(0)

    print "Delivering " + str(msg) + " to 0 at " + str(t.time() + 3)
    pkt.deliver(0, t.time() + 3)

if __name__ == "__main__":
    main(sys.argv[1:])
