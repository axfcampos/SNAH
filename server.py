#! /usr/bin/python

# ASE Project 2013/2014 - Instituto Superior Tecnico
# @author - Alexandre Filipe Campos - 66354

import sys
import math
import time
import os
import random
from TOSSIM import *
from tinyos.tossim.TossimApp import *
from threading import Thread
from PingMsg import *
from UpdateFoodDailyDosage import *
from GetFoodDailyDosage import *

def main(argv):


    #vars
    global n_nodes, t, r, msg_id, nodeList
    MAX_NODES = 10000
    nodeList = []
    random.seed()


    n = NescApp()
    t = Tossim(n.variables.variables())
    #what = t.mac()
    r = t.radio()

    # === Welcome
    print "ASE Project 2013/2014 by Alexandre Campos"
    print "+++ "

    # === add debug and log channels ===
    t.addChannel("Boot", sys.stdout)
    t.addChannel("FoodInfo", open("food_info.txt", "w"))


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
        elif cmd[0] == "get":
            if(len(cmd) < 2):
                print "wrong input. get <mote_id>"
                continue
            get_state_info(cmd[1])
        elif cmd[0] == "updateFood":
            if len(cmd) == 3:
                updateFood(int(cmd[1]), int(cmd[2]))
            else:
                print "command usage updateFood <mote_id> <amount>"
                print "if ( <mote_id> = 0 ) ---> update to all motes"
        elif cmd[0] == "getFood":
            print "gonna get food"
            if len(cmd) == 2:
                getFood(int(cmd[1]))
            else:
                print "command usage getFood <mote_id>"
                print "if ( <mote_id = 0 ) ---> get from all motes "
        elif cmd[0] == "ping":
            ping()
        elif cmd[0] == "exit":
            print "leaving . . . . goodbye!"
            os._exit(0)
            break
        elif cmd[0] == "h":
            help_me()
        else:
            print "wrong input. type 'h' for help"

def updateFood(mote_id, food):
    msg = UpdateFoodDailyDosage()
    msg.set_msg_id(random.randint(0, pow(2,32)- 1))
    msg.set_new_food_maxkg(food)
    msg.set_mote_dest(mote_id)

    pkt = t.newPacket()
    pkt.setData(msg.data)
    pkt.setType(msg.get_amType())
    pkt.setDestination(0)

    print "Delivering " + str(msg) + " to 0 at " + str(t.time() +3)
    pkt.deliver(0, t.time() + 3)

def getFood(mote_id):
    msg = GetFoodDailyDosage()
    msg.set_mote_dest(mote_id)
    msg.set_msg_id(random.randint(0, pow(2,32)-1))

    pkt = t.newPacket()
    pkt.setData(msg.data)
    pkt.setType(msg.get_amType())
    pkt.setDestination(0)

    print "Delivering " + str(msg) + " to 0 at " + str(t.time() +3)
    pkt.deliver(0, t.time() + 3)


def get_state_info(mote_id):
    try:
        mote = nodeList[int(mote_id)]
        status = mote.isOn()
        max_food = mote.getVariable("AnimalC.max_food")
        food_intake = mote.getVariable("AnimalC.food_intake")

        print "Status: " + str(status) + " | Max_food: " + str(max_food.getData()) + " | food_in: " + str(food_intake.getData())
    except Exception:
        print "error.... how to use get: get <mote_id>"

def help_me():
    print "- h                                 *** for help"
    print "- get <mote_id>                     *** get state info of mote"
    print "- ping                              *** to ping all nodes"
    print "- exit                              *** to exit"
    print "- updateFood <mote_id> <amount>     *** to update daily food. mote_id 0 for all"
    print "- getFood <mote_id>                 *** to get amount of food consumed. mote_id 0 for all"
    print "- getPosition <mote_id>             *** to get mound GPS position. mote_id 0 for all "
    print "- getLastPosition <mote_id>...      *** to get the last know GPS position of select nodes."
    print "- getSpotFood <spot_id>             *** to get amount of food left in feeding spot. 0 to get all."
    print "- updateSpotFood <spot_id> <amount> *** to update the spots food. 0 for all."


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
