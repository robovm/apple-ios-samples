### InterAppAudioHost ###

InterAppAudioHost allows iOS audio applications that are remote instruments, effects or generators to publish an output which can be used by other audio applications. These applications which publish an output are known as nodes. Any application which connects and utilizes these node applications is a host. This is an example of a host application.

This example is intended to be used with the node examples InterAppAudioDelay and InterAppAudioSampler.

Demo Application Notes
  • In the interest of simplicity, removing the effect node also removes the instrument node. A well-behaved host application should add the necessary code to make these two
    independent
  • The transport code shows an example of how a transport mechanism may be implemented. Applications are free to implement more advanced functionality and alternate appearances
    that go better with the user interface of the specific application
  • When connecting a remote generator node instead of an instrument, playing notes on the keyboard will have no effect as the remote node does not listen to MIDI events
  • Playing the keyboard on the host will sound different than playing the keyboard from the node. This is because the host's keyboard is several octaves lower than the start note on the node. This was intentional to demonstate the differences between triggering a note via MIDI from the host vs. directly triggering the note from the node.
    
===========================================================================
Copyright (C) 2013-2014 Apple Inc. All rights reserved.
