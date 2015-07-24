# LogstashConfigCreate
A tool to create logstash configuration files. Currently very unstable.

## Requirements  
ruby 2.0.0  
gem jls-grok 0.11.2  

##User Instructions
This program generates a file from a series of branches, each containing various filters.   
Run `ruby main.rb YOURLOGFILE` to start the step by step   
The program follows a hierarchical structure where typeing 'next' will usually take you back.     

Logfiles are represented in a similar manner to probability trees.
For example here is a logfile:    
```
[1436569531] PROCESS_SERVICE_CHECK_RESULT: SWAP 100% free (out of 8193 MB)  
[1436569632] PASSIVE SERVICE CHECK: node4;All_OK  
[1436682699] CURRENT HOST STATE: node1;UP;HARD;1;PING OK - Packet loss = 0%, RTA = 0.20 ms  
[1436688700] CURRENT HOST STATE: node5;UP;HARD;1;PING OK - Packet loss = 0%, RTA = 0.23 ms  
[1436682700] CURRENT HOST STATE: node2;DOWN;HARD;1;CRITICAL - Host Unreachable (64.233.191.255)
```


This could be represented as:
>```
{{...}}}
    |---[{TIMESTAMP}] {{...}}  
                         |-PROCESS_SERVICE_CHECK_RESULT: {{...}}  
                         |                                  |-SWAP {FREESWAP}% free (out of {TOTALMEM} MB)
                         |
                         |-PASSIVE SERVICE CHECK: {{...}}  
                         |                           |-{NODENAME};{STATUS}  
                         |
                         |-CURRENT HOST STATE:  {NODENAME} ; {{...}}  
                                                                |  
                                                                |- UP;HARD;1;PING OK - Packet loss = {PACKETLOSS}%, RTA = {RTA} ms  
                                                                |  
                                                                |- ;DOWN;HARD;1;CRITICAL - Host Unreachable ({IPADDRESS})  


The program helps you to construct something similar to this for a log and then converts it to a logstash json output.  
  
  For each branch a number of filters are supported. Currently it includes grok, drop, timestamp and convert  
* **Grok** takes text and captures variables within it. It is built on top of regular expressions  
* **Drop** simple tells logstash to ignore everything that gets to that branch and not output the message  
* **Timestamp** allows you to change the default timestamp of the message (set to when Logstash discovers a message) to when the log message was actually generated 
* **Convert** allows you to convert a captured variable into a different type (usually a integer or float)  

For the log above you would create a *grok* tree similar to the structure above, 
you would probably *drop* all messages in the `UP;HARD;1;PING OK` branch as they aren't very useful,
use *timestamp* to convert the UNIX timestamp into the timestamp field
and then use *convert* to change `{FREESWAP}` and `{TOTAL MEM}` into integers
  
