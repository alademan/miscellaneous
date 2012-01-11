import weechat
import imaplib

# AUTHOR: Tony Lademan <tony@alademan.com>
#
# REQUIREMENTS:
#   This script will require the IMAPLIB python module in order to
#   function.  Without the module installed on your system, this script
#   will fail.  Please refer to the appropriate documentation for your
#   python configuration to install the IMAPLIB module on your system.
#     http://docs.python.org/library/imaplib.html
#
# USAGE:
#   Load the plugin in weechat using 
#     /python load PATH_TO_SCRIPT
#
#   Set up the options using the standard weechat style
#     /set plugins.var.python.email_reply.username "tony@alademan.com"
#
#   Send an email to that account that fits the format you defined
#     i.e. Using my setup:
#       From: my_other_address@domain.com
#       To: "Away_Log" <tony@alademan.com>
#       Subject: David-[AIM]
#       Body:
#         What's up.
#     This will send a message to David's AIM screenname.  Using bitlbee,
#     I renamed this user to "David-[AIM]"  So, for example, if you have
#     my AIM on your contact list and have not renamed me, you'd set the
#     subject to "itstonylol".
#
#   If you decide to automatically filter these messages into a different
#   label or folder, set the "imap_folder" name appropriately.  I set this
#   to "Away_Log" and have a gmail filter automatically move it there.  If
#   this doesn't matter to you, the default is the inbox.
#
#   This seems pretty useless on its own, but I can see a few instances
#   where it might come in handy as a quick way to send someone a message
#   when you don't have their number for a quick text message or something.
#   I use it in conjunction with the away_action.py weechat script
#     ( http://www.weechat.org/scripts/source/stable/away_action.py.html/ )
#   which I set up to send me an email whenever someone messages me and I
#   am away.  The email is sent using your standard unix mail.  This set up 
#   allows me to receive messages on my phone when I am away from my 
#   computer and, if I so choose, respond to them just by replying to the
#   email.  The entire purpose is to avoid having to log in to my computer
#   via SSH over a sometimes unreliable or otherwise slow 3G connection.
#
#   To add a string to indicate a signature (or where the script should
#   stop reading the message):
#     /add_signature STRING
#
#   To remove a string:
#     /remove_signature STRING
#
#   To list all strings:
#     /list_signature
#
#   NOTE:  This currently only works on one server.  It should not require 
#          bitlbee, but I have not yet tested it otherwise. 

# TODO:
#   * Add help message(s) describing the options
#
#   * Allow for using multiple servers (so that it works on IRC, too)
#     - Find a way to get around requiring an open control channel buffer
#       - Not entirely sure how to do this.  If I run weechat.command and pass 
#         an empty string as the buffer, then it sends on the core buffer, 
#         which may or may not be the appropriate server, and thus may query
#         a user on an inappropriate server.
#           i.e. If I respond to a message from the itstonylol AIM screenname,
#                 but my core buffer is currently focused on the freenode 
#                 server, then it may query itstonylol on freenode.
#       - Where do I send from if no control channel buffer?  Do I send from
#         the core buffer?  As above, what if the core buffer is focused on a
#         different server?  
#       - I haven't found anything that shows how to find the server on which
#         a message was received.  If I had that, then I could just append it
#         to the outgoing email notification (i.e. the subject would now read
#         "Jason-[AIM] on server aim" or "sugardeath on server freenode", thus
#         allowing me to parse the relevant data and send it from the correct
#         server using:
#           buffer = weechat.info_get("irc_buffer", SERVER_NAME + "," + 
#                         APPROPRIATE_CHANNEL)
#           weechat.command(buffer, "/query " + USER + " " + MESSAGE)
#       - The reason I need a control channel/buffer is because I need an open
#         buffer from which to send the command.  I can't assume the buffer 
#         for a particular user is open, especially if I am sending a new 
#         message and not replying to a received one.  
#         - Simiarly, if I have a buffer open for itstonylol on aim as well as
#           a buffer for itstonylol on freenode, which will it choose?  
#
#   * Support multi-line messages (yet don't send the quoted email)
#     - Should be working.  Play with this a bit and make sure nothing funny
#       happens.
#
#   * General Housekeeping
#
#   * Error checking
#     - Catch failed logins or timeouts and report them in a sane fashion.
#       Currently the stderr output is thrown directly to the core buffer.

SCRIPT_NAME = "email_reply"
SCRIPT_AUTHOR = "Tony Lademan <tony@alademan.com>"
SCRIPT_VERSION = "0.1"
SCRIPT_LICENSE = "GPL3"
SCRIPT_DESCRIPTION = "Reply to messages using email"

weechat.register(SCRIPT_NAME, SCRIPT_AUTHOR, SCRIPT_VERSION, SCRIPT_LICENSE, SCRIPT_DESCRIPTION, "", "")

script_options = {
    "username"                : "",
    "password"                : "",
    "imap_server"             : "imap.gmail.com",
    "imap_folder"             : "inbox",
    "recipient_name"          : "",
    "bitlbee_control_channel" : "&bitlbee",
    "bitlbee_server_name"     : "localhost",
    "frequency"               : "2.5",
    "signature_lines"         : "",
}

if weechat.config_get_plugin("signature_lines") != "":
  signature_list = weechat.config_get_plugin("signature_lines").split(",")
else:
  signature_list = []

for option, default_value in script_options.iteritems():
  if not weechat.config_is_set_plugin(option):
    weechat.config_set_plugin(option, default_value)

def config_cb(data, option, value):
  return weechat.WEECHAT_RC_OK

weechat.hook_config("plugins.var.python." + SCRIPT_NAME + ".*", "config_cb", "")

def check_and_send():
  subject = ""
  body = ""
  mail = imaplib.IMAP4_SSL(
      weechat.config_get_plugin("imap_server")
      )
  mail.login(
      weechat.config_get_plugin("username"),
      weechat.config_get_plugin("password")
      )
  mail.select(
      weechat.config_get_plugin("imap_folder")
      )
  mail.recent()
  search_status,mail_uids = mail.uid('search', None, '(HEADER To "'
      + weechat.config_get_plugin("recipient_name")
      + '" UNSEEN)')
  mail_uids = mail_uids[0].split()
  if len(mail_uids) != 0:
    weechat.prnt("", "checking")
    for uid in mail_uids:
      result, data = mail.uid('fetch', uid, '(RFC822)')
      message = data[0][1]
      counter = 0
      targetline = None
      copy_message = False
      for line in message.split('\n'):
        if "Subject: " in line:
          subject = line.replace("Subject: ", "")
          subject = subject.replace("Re: ", "")
          subject = subject.strip()
        if "Content-Type: text/plain" in line:
          targetline = counter + 2
        if counter == targetline:
          copy_message = True
          weechat.prnt("", "read")
        for word in signature_list:
          if word in line:
            copy_message = False;
            weechat.prnt("", "stop read")
        if copy_message == True: 
          body = body + line
          weechat.prnt("", body)
        counter += 1
      buffer = weechat.info_get("irc_buffer", weechat.config_get_plugin("bitlbee_server_name") + "," + weechat.config_get_plugin("bitlbee_control_channel"))
      weechat.command(buffer, "/query " + subject + " " + body)
  mail.close()
  mail.logout()

def call_check_and_send(data, buffer, args):
  check_and_send()
  return weechat.WEECHAT_RC_OK

def add_signature_line(data, buffer, args):
  signature_list.append(args)
  weechat.prnt("", "Added " + args + " to signature list.  List contains:")
  for each in signature_list:
    weechat.prnt("", "  " + each)
  array_to_string()
  return weechat.WEECHAT_RC_OK

def remove_signature_line(data, buffer, args):
  if args in signature_list:
    del signature_list[signature_list.index(args)]
    weechat.prnt("", "Item " + args + " removed from signature list, now contains:")
    for each in signature_list:
      weechat.prnt("", "  " + each)
  else:
    weechat.prnt("", "Item " + args + " not in signature list.")
  array_to_string()
  return weechat.WEECHAT_RC_OK

def list_signature_line(data, buffer, args):
  weechat.prnt("", "Items in signature list:")
  for each in signature_list:
    weechat.prnt("", "  " + each)
  return weechat.WEECHAT_RC_OK

def array_to_string():
  out = ','.join(signature_list)
  weechat.config_set_plugin("signature_lines", out)

hook = weechat.hook_command("fetch_replies", "Force a IMAP pull of replies", "", "", "", "call_check_and_send", "")
hook = weechat.hook_command("add_signature", "Add a line to the signature array to signify the end of the message body", "", "", "", "add_signature_line", "")
hook = weechat.hook_command("list_signature", "List all of the items that indicate a signature", "", "", "", "list_signature_line", "")
hook = weechat.hook_command("remove_signature", "Remove a line from the signature array", "", "", "", "remove_signature_line", "")

def my_timer(data, remaining_calls):
  check_and_send()
  return weechat.WEECHAT_RC_OK

seconds = float(weechat.config_get_plugin("frequency")) * 60
weechat.hook_timer(int(seconds) * 1000, 60, 0, "my_timer", "my data")
