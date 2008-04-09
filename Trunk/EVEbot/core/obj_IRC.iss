objectdef obj_IRC
{       
    variable bool IsConnected = FALSE
                  
	method Initialize()
	{			
#if USE_ISXIRC
	    ext -require ISXIRC

		Event[IRC_ReceivedNotice]:AttachAtom[This:IRC_ReceivedNotice]
        Event[IRC_ReceivedChannelMsg]:AttachAtom[This:IRC_ReceivedChannelMsg]	
        Event[IRC_ReceivedPrivateMsg]:AttachAtom[This:IRC_ReceivedPrivateMsg]
        Event[IRC_TopicSet]:AttachAtom[This:IRC_TopicSet]
        Event[IRC_NickChanged]:AttachAtom[This:IRC_NickChanged]
        Event[IRC_KickedFromChannel]:AttachAtom[This:IRC_KickedFromChannel]	
        Event[IRC_ReceivedCTCP]:AttachAtom[This:IRC_ReceivedCTCP]	
        Event[IRC_PRIVMSGErrorResponse]:AttachAtom[This:IRC_PRIVMSGErrorResponse]	
        Event[IRC_JOINErrorResponse]:AttachAtom[This:IRC_JOINErrorResponse]	
        Event[IRC_NickTypeChange]:AttachAtom[This:IRC_NickTypeChange]
        Event[IRC_NickJoinedChannel]:AttachAtom[This:IRC_NickJoinedChannel]
        Event[IRC_NickLeftChannel]:AttachAtom[This:IRC_NickLeftChannel]
        Event[IRC_NickQuit]:AttachAtom[This:IRC_NickQuit]
        Event[IRC_ReceivedEmote]:AttachAtom[This:IRC_ReceivedEmote]
        Event[IRC_ChannelModeChange]:AttachAtom[This:IRC_ChannelModeChange]
        Event[IRC_AddChannelBan]:AttachAtom[This:IRC_AddChannelBan]
        Event[IRC_RemoveChannelBan]:AttachAtom[This:IRC_RemoveChannelBan]
        Event[IRC_UnhandledEvent]:AttachAtom[This:IRC_UnhandledEvent]

		UI:UpdateConsole["obj_IRC: Initialized", LOG_MINOR]
#endif
	}
	
	method Shutdown()
	{
#if USE_ISXIRC
		Event[IRC_ReceivedNotice]:DetachAtom[This:IRC_ReceivedNotice]
        Event[IRC_ReceivedChannelMsg]:DetachAtom[This:IRC_ReceivedChannelMsg]	
        Event[IRC_ReceivedPrivateMsg]:DetachAtom[This:IRC_ReceivedPrivateMsg]
        Event[IRC_TopicSet]:DetachAtom[This:IRC_TopicSet]
        Event[IRC_NickChanged]:DetachAtom[This:IRC_NickChanged]
        Event[IRC_KickedFromChannel]:DetachAtom[This:IRC_KickedFromChannel]	
        Event[IRC_ReceivedCTCP]:DetachAtom[This:IRC_ReceivedCTCP]	
        Event[IRC_PRIVMSGErrorResponse]:DetachAtom[This:IRC_PRIVMSGErrorResponse]	
        Event[IRC_JOINErrorResponse]:DetachAtom[This:IRC_JOINErrorResponse]	    
        Event[IRC_NickTypeChange]:DetachAtom[This:IRC_NickTypeChange]
        Event[IRC_NickJoinedChannel]:DetachAtom[This:IRC_NickJoinedChannel]
        Event[IRC_NickLeftChannel]:DetachAtom[This:IRC_NickLeftChannel]    
        Event[IRC_NickQuit]:DetachAtom[This:IRC_NickQuit]
        Event[IRC_ReceivedEmote]:DetachAtom[This:IRC_ReceivedEmote]
        Event[IRC_ChannelModeChange]:DetachAtom[This:IRC_ChannelModeChange]
        Event[IRC_AddChannelBan]:DetachAtom[This:IRC_AddChannelBan]
        Event[IRC_RemoveChannelBan]:DetachAtom[This:IRC_RemoveChannelBan]
        Event[IRC_UnhandledEvent]:DetachAtom[This:IRC_UnhandledEvent]    
#endif
	}
		
    method IRC_ReceivedNotice(string User, string From, string To, string Message)
    {
    	  ; This event is fired every time that an IRCUser that you have connected
    	  ; receives a NOTICE.  You can do anything fancy you want with this, but,
    	  ; for now, we're just going to echo it to the console window.
    	  
    	  ; Deal with Nickserv:  
    	  if (${From.Equal[Nickserv]})
    	  {
    	  	  if (${Message.Find[This nickname is registered and protected]})
    	  	  {
    	  	  	  ; Send the password to Nickserv.  You might want to do this 
    	  	  	  ; more elegantly by saving passwords in the script via variables
    	  	  	  ; or xml.
    	  	  	  if (${To.Equal[${Config.Common.IRCUser}]})
    	  	  	  {
    	  	  	     IRCUser[${Config.Common.IRCUser}]:PM[Nickserv,"identify ${Config.Common.IRCPassword}"]
    	  	  	  }
    	  	  	  return
    	  	  }
    	  	  elseif (${Message.Find[Password accepted]})
    	  	  {
    	  	  		echo [${To}] Identify with Nickserv successful
    	  	  		
    	  	      ; if this was an attempt to register the nick after having been
    	  	      ; denied access to a channel, we want to indicate that it was
    	  	      ; successful by resetting the number of attempts to zero
    	  	  		if (${RegisteredChannelRetryAttempts} > 0)
    	  	  		   RegisteredChannelRetryAttempts:Set[0]
    	  	  		return
    	  	  }
    	  	  elseif (${Message.Find[Password incorrect]})
    	  	  {
    	  	  	  echo Incorrect password while attempting to identify ${To} with Nickserv
    	  	  	  return
    	  	  }
    	  	  elseif (${Message.Find[Password authentication required]})
    	  	  {
    	  	  	  echo Password authentication is required before you can issue commands to Nickserv
    	  	  	  return
    	  	  }
    	  	  elseif (${Message.Find[nick, type]})
    	  	  {
    	  	  	 ; Junk message we don't need to see
    	  	  	 return
    	  	  }
    	  	  elseif (${Message.Find[please choose a different]})
    	  	  {
    	  	  	; Junk message we don't need to see
    	  	  	return
    	  	  }
    	  }
    	  
    	  if (${Message.Find[DCC Send]})
    	  {
    	  	 	; This is handled by the CTCP event -- I'm not sure why clients send both
    	  	  ; a NOTICE and a CTCP when they're dcc'ing files
    	  	  return
    	  }	  
    	  elseif (${Message.Find[DCC Chat]})
    	  {
    	  	 	; This is handled by the CTCP event -- I'm not sure why clients send both
    	  	  ; a NOTICE and a CTCP when they're dcc'ing files
    	  	  return
    	  }	  	  
    	  
    	  echo [${User}] ${To} just received a NOTICE from ${From} :: "${Message}"
    }
    
    method IRC_ReceivedChannelMsg(string User, string Channel, string From, string Message)
    {
    	  ; This event is fired every time that an IRCUser that you have connected
    	  ; receives a Channel Message.  You can do anything fancy you want with this, 
    	  ; but, for now, we're just going to echo it to the console window.
    	  
    	  echo [${User} - ${Channel}] -- (${From}) "${Message}"
    }
    
    method IRC_ReceivedPrivateMsg(string User, string From, string To, string Message)
    {
    	  ; This event is fired every time that an IRCUser that you have connected
    	  ; receives a Private Message.  You can do anything fancy you want with this, 
    	  ; but, for now, we're just going to echo it to the console window.
    	  
    	  ; NOTE: ${User} should always be the same as ${To} in this instance.  However, it is
    	  ;       included for continuity's sake.
    	  
    	  echo [Private Message -> ${To}] (${From}) "${Message}"
    }
    
    method IRC_ReceivedEmote(string User, string From, string To, string Message)
    {
    	  ; This event is fired every time that an IRCUser recognizes an "emote"
    	  ; from another user.  Please note that ${To} is typically a 'channel' 
    	  ; in this event.
    	  
    	  echo [${User} - ${To}] ${From} "${Message}"
    }
    
    method IRC_ReceivedCTCP(string User, string From, string To, string Message)
    {
    	  ; This event is fired every time that an IRCUser that you have connected
    	  ; receives a CTCP request.
    	  ; IMPORTANT:  isxIRC handles all of these requests for you, so this
    	  ;             event is only here to let you know that it occured.
    	  
    	  echo [${User} - CTCP from ${From} to ${To}] "${Message}"
    }
    
    method IRC_TopicSet(string User, string Channel, string NewTopic, string TopicSetBy)
    {
    	  ; This event is fired every time that someone changes the topic of a channel
    	  ; of which one of your IRCUser connections is a part.  You can do anything 
    	  ; fancy you want with this, but, for now, we're just going to echo it to the 
    	  ; console window.
    	  
    	  echo [${User} - ${Channel}] New Topic: "'${NewTopic}'" (by ${TopicSetBy})
    }
    
    method IRC_NickChanged(string User, string OldNick, string NewNick)
    {
    	  ; This event is fired every time that someone changes their NICK in a channel
    	  ; of which one of your IRCUser connections is a part.  You can do anything 
    	  ; fancy you want with this, but, for now, we're just going to echo it to the 
    	  ; console window.
    	  
    	  echo [${User}] '${OldNick}' has changed their Nick to '${NewNick}'
    }
    
    method IRC_KickedFromChannel(string User, string Channel, string WhoKicked, string KickedBy, string Reason)
    {
    		; This event is fired every time that one of your IRCUsers are kicked from a 
    		; channel.  You can do anything fancy you want to do with this, but, for now, we're
    		; just going to echo the information to the console window
    		
    		echo [${User}] ${WhoKicked} has been KICKED from ${Channel}!
    		echo Reason: "${Reason}" (by ${KickedBy})
    		
    		; Auto rejoin! :)
    		IRCUser[${WhoKicked}]:Join[${Channel}]
    }
    
    method IRC_NickJoinedChannel(string User, string Channel, string WhoJoined)
    {
    	  ; This event is fired every time that someone joins a channel other than 
    	  ; the IRCUser.
    	  
    	  echo [${User} - ${Channel}] ${WhoJoined} has joined channel ${Channel}.
    }
    
    method IRC_NickLeftChannel(string User, string Channel, string WhoLeft)
    {
    		; This event is fired every time that someone leaves a channel other than
    		; the IRCUser.  This event is NOT fired when someone (or yourself) is KICKED
    		
    		echo [${User} - ${Channel}] ${WhoLeft} has left channel ${Channel}
    }
    
    method IRC_NickQuit(string User, string Channel, string Nick, string Reason)
    {
    	  ; This event is fired every time that someone QUITS the server
    	  if (${Channel.Length} == 0 )
    		{
    				echo [${User}] ${Nick} has QUIT. (${Reason})
    		}
    		else
    		{
    				echo [${User} - ${Channel}] ${Nick} has QUIT. (${Reason})
    		}
    }
    
    method IRC_PRIVMSGErrorResponse(string User, string ErrorType, string To, string Response)
    {
    	  ; This event is fired whenever an IRCUser that you have connected receives an
    	  ; error response while trying to send a PM.  
    	  ; NOTE: The IRC protocol considers a message sent to a channel to be a "PM" to
    	  ; that channel.
    	  
    	  ; Possible ${ErrorType} include: "NO_SUCH_NICKORCHANNEL", "NO_EXTERNAL_MSGS_ALLOWED"
    	  
    	  if (${ErrorType.Equal[NO_SUCH_NICKORCHANNEL]})
    		{
    			  echo [${User}] Sorry, '${To}' does not exist. 
            return
        }
        elseif (${ErrorType.Equal[NO_EXTERNAL_MSGS_ALLOWED]})
        {
        	  echo [${User}] Sorry, ${To} does not allow for external messages.
        	  echo [${User}] You will need to join ${To} in order to send messages to the channel.
        	  return
        }
    }
     
    method IRC_JOINErrorResponse(string User, string ErrorType, string Channel, string Response)
    {
     		; This event is fired whenever an IRCUser that you have connected receives an
    	  ; error response while trying to join a channel.  
    
    		; Possible ${ErrorType} include: "BANNED", "MUST_BE_REGISTERED"
    
     		if (${ErrorType.Equal[BANNED]})
     		{
     			 	echo [${User}] Sorry, you have been banned from ${Channel}!
     			 	return
     		}
     		elseif (${ErrorType.Equal[REQUIRES_KEY]})
     		{
     			  echo [${User}] Sorry, this channel requires a password.
     			  return
        }
     		elseif (${ErrorType.Equal[MUST_BE_REGISTERED]})
     		{
     			  echo [${User}] Received a message that we were not identified/registered.
     			  
     			  ; We will try and identify with nickserv and rejoin a total of 5 times before giving up.
     			  ; This is necessary because sometimes the script will try and join a registered channel
     			  ; before nickserv has a chance to acknowledge identification.  Again, this method is
     			  ; not very elegant because the passwords are hardcoded; however, it proves the point.
     			  if (${RegisteredChannelRetryAttempts} <= 5)
     			  {
     			  	echo [${User}] Identifying with Nickserv now.
        	  	  	if (${UserName.Equal[${Config.Common.IRCUser}]})
        	  	  	{
        	  	  			IRCUser[${Config.Common.IRCUser}]:PM[Nickserv,"identify ${Config.Common.IRCPassword}"]
        	  	  	}
    		  		IRCUser[${User}]:Join[${Channel}]
    		  		RegisteredChannelRetryAttempts:Inc
     			  	return
     			  }
     		}
    }
    
    method IRC_AddChannelBan(string User, string Channel, string WhoSet, string Ban)
    {
    	  ; This event is fired whenever an IRCUser that you have connected receives a
    	  ; message that a ban has been added to the channel.   isxIRC handles updating
    	  ; the banlist for each channel, so this event is just here for notifying the 
    	  ; user
    	  
    		echo [${User} - ${Channel}] ${WhoSet} has banned "${Ban}"!
    }
    
    method IRC_RemoveChannelBan(string User, string Channel, string WhoSet, string Ban)
    {
    	  ; This event is fired whenever an IRCUser that you have connected receives a
    	  ; message that a ban has been removed from a channel.   isxIRC handles updating
    	  ; the banlist for each channel, so this event is just here for notifying the 
    	  ; user
    	  
    		echo [${User} - ${Channel}] ${WhoSet} has removed the ban "${Ban}"!
    }	
    
    method IRC_UnhandledEvent(string User, string Command, string Param, string Rest)
    {
    	  ; This event is here to handle any events that are not handled otherwise by the
    	  ; the extension.  There will probably be a lot of spam here, so you won't want to
    	  ; echo everything.  The best thing to do is only use this event when there is something
    	  ; that is happening with the client that you want added as a feature to isxIRC and need
    	  ; the data to tell Amadeus.
    	  
    	  ; However, we do want any ERROR messages!
    	  if (${Command.Equal[ERROR]})
    	  {
    	  	  echo CRITICAL IRC ERROR: ${Rest}
    	  }
    }
    	
    method IRC_NickTypeChange(string User, string Channel, string NickName, string NickType, string Toggle, string WhoSet)
    {
     		; This event is fired whenever an IRCUser that you have connected receives an
    	  ; message that a nick has had their 'type' changed on a channel (ie, being set
    	  ; as an OP)
    	  
    	  ; Possible ${NickType} include: "OWNER", "SOP", "OP", "HOP", "Voice", "Normal"
    	  ; Possible ${Toggle} include: "TRUE, "FALSE"
    	  
    	  ; Ok, first of all, if it's Chanserv that's doing the MODE changing, we just don't
    	  ; care enough to echo it.  If you want to utilize it in your scripts otherwise, feel
    	  ; free!
    	  if (${WhoSet.Find[Chanserv]})
    	     return
    	  
    	  ; NOTE:  isxIRC takes care of updating the Nicks lists for all channels with their 
    	  ;        'type'.  So, the script is only responsible for notifying the user or any
    	  ;        other custom functions desired. 
    	 
    	  if (${NickType.Equal[OWNER]})
    	  {
    	  	  if (${Toggle.Equal[TRUE]})
    	  	      echo [${User}] ${NickName} has been made an OWNER on ${Channel} by ${WhoSet}!
    	  	  else
    	  	      echo [${User}] ${NickName} has had their OWNER flag removed on ${Channel} by ${WhoSet}!
     	  }
    	  elseif (${NickType.Equal[SOP]})
    	  {
    	  	  if (${Toggle.Equal[TRUE]})
    	  	      echo [${User}] ${NickName} has been made a SUPER OPERATOR on ${Channel} by ${WhoSet}!
    	  	  else
    	  	      echo [${User}] ${NickName} has had their SUPER OPERATOR flag removed on ${Channel} by ${WhoSet}!
     	  }
    	  elseif (${NickType.Equal[OP]})
    	  {
    	  	  if (${Toggle.Equal[TRUE]})
    	  	      echo [${User}] ${NickName} has been made an OPERATOR on ${Channel} by ${WhoSet}!
    	  	  else
    	  	      echo [${User}] ${NickName} has had their OPERATOR flag removed on ${Channel} by ${WhoSet}!
     	  }
     	  elseif (${NickType.Equal[HOP]})
    	  {
    	  	  if (${Toggle.Equal[TRUE]})
    	  	      echo [${User}] ${NickName} has been made a HALF OPERATOR on ${Channel} by ${WhoSet}!
    	  	  else
    	  	      echo [${User}] ${NickName} has had their HALF OPERATOR flag removed on ${Channel} by ${WhoSet}!
     	  }	  
    	  elseif (${NickType.Equal[VOICE]})
    	  {
    	  	  if (${Toggle.Equal[TRUE]})
    	  	      echo [${User}] ${NickName} has been made a VOICE on ${Channel} by ${WhoSet}!
    	  	  else
    	  	      echo [${User}] ${NickName} has had their VOICE flag removed on ${Channel} by ${WhoSet}!
     	  } 	    	   	  
    }
     
    method IRC_ChannelModeChange(string User, string Channel, string ModeType, string Toggle, string WhoSet, string Extra)
    {
     		; This event is fired whenever an IRCUser that you have connected receives an
    	  ; message that a channel has had its 'mode' changed.
    	  ; NOTE:  This event will fire for every user that's in a channel!  So, if you
    	  ;        have more than one user in a channel, you'll get duplicate messages :)
    	  
    	  ; Possible ${ModeType} include: "PASSWORD", "LIMIT", "SECRET", "PRIVATE", "INVITEONLY",
        ;                               "MODERATED", "NOEXTERNALMSGS", "ONLYOPSCHANGETOPIC", "REGISTERED",
        ;                               "REGISTRATIONREQ", "NOCOLORSALLOWED"
    
    	  ; Possible ${Toggle} include: "TRUE, "FALSE"
    
    		; Possible ${Extra} include:  The "password" for the PASSWORD ${ModeType} and the "limit"
    		;                             for the LIMIT ${ModeType}
    	  
    	  
    	  ; Ok, first of all, if it's the server that's doing the MODE changing, we just don't
    	  ; care enough to echo it.  If you want to utilize it in your scripts otherwise, feel
    	  ; free!   
    	  variable int i = 1
    	  do
    	  {
    	  	 if (${IRCUser[${i}].Server.Equal[${WhoSet}]})
    	  	     return
    	  }
    		while (${i:Inc} <= ${IRC.NumUsers})
    	
    	  ; NOTE:  isxIRC takes care of updating the Channel lists within the extension.  So, the 
    	  ;        script is only responsible for notifying the user or any other custom functions desired. 
    	 
    	  if (${ModeType.Equal[PASSWORD]})
    	  {
    	  	  if (${Toggle.Equal[TRUE]})
    	  	      echo [${User}] A PASSWORD has been set on ${Channel}: ${Extra}  (${WhoSet})
    	  	  else
    	  	      echo [${User}] ${WhoSet} has removed the PASSWORD on ${Channel}
     	  }
    	  elseif (${ModeType.Equal[LIMIT]})
    	  {
    				if (${Toggle.Equal[TRUE]})
    						echo [${User}] A LIMIT has been placed on ${Channel} of ${Extra} Users!  (${WhoSet})
    			  else
    			   		echo [${User}] ${WhoSet} has removed the user LIMIT on ${Channel}
        }
        elseif (${ModeType.Equal[SECRET]})
        {
        	  if (${Toggle.Equal[TRUE]})
        	   		echo [${User}] ${Channel} has been designated as SECRET by ${WhoSet}
        	  else
        	      echo [${User}] ${WhoSet} has removed the SECRET flag from ${Channel}
        }
        elseif (${ModeType.Equal[PRIVATE]})
        {
        	  if (${Toggle.Equal[TRUE]})
        	   		echo [${User}] ${Channel} has been designated as PRIVATE by ${WhoSet}
        	  else
        	      echo [${User}] ${WhoSet} has removed the PRIVATE flag from ${Channel}
        }    
        elseif (${ModeType.Equal[INVITEONLY]})
        {
        	  if (${Toggle.Equal[TRUE]})
        	   		echo [${User}] ${Channel} has been designated as INVITE ONLY by ${WhoSet}
        	  else
        	      echo [${User}] ${WhoSet} has removed the INVITE ONLY flag from ${Channel}
        }    
        elseif (${ModeType.Equal[MODERATED]})
        {
        	  if (${Toggle.Equal[TRUE]})
        	   		echo [${User}] ${Channel} has been designated as MODERATED by ${WhoSet}
        	  else
        	      echo [${User}] ${WhoSet} has removed the MODERATED flag from ${Channel}
        }    
        elseif (${ModeType.Equal[NOEXTERNALMSGS]})
        {
        	  if (${Toggle.Equal[TRUE]})
        	   		echo [${User}] ${Channel} has been designated as NO EXTERNAL MESSAGES by ${WhoSet}
        	  else
        	      echo [${User}] ${WhoSet} has removed the NO EXTERNAL MESSAGES flag from ${Channel}
        }  
        elseif (${ModeType.Equal[ONLYOPSCHANGETOPIC]})
        {
        	  if (${Toggle.Equal[TRUE]})
        	   		echo [${User}] ${Channel} has been designated as ONLY OPS CHANGE TOPIC by ${WhoSet}
        	  else
        	      echo [${User}] ${WhoSet} has removed the ONLY OPS CHANGE TOPIC flag from ${Channel}
        }      
        elseif (${ModeType.Equal[REGISTERED]})
        {
        	  if (${Toggle.Equal[TRUE]})
        	   		echo [${User}] ${Channel} has been designated as REGISTERED by ${WhoSet}
        	  else
        	      echo [${User}] ${WhoSet} has removed the REGISTERED flag from ${Channel}
        }
        elseif (${ModeType.Equal[REGISTRATIONREQ]})
        {
        	  if (${Toggle.Equal[TRUE]})
        	   		echo [${User}] ${Channel} has been designated as REGISTRATION REQUIRED by ${WhoSet}
        	  else
        	      echo [${User}] ${WhoSet} has removed the REGISTRATION REQUIRED flag from ${Channel}
        }
        elseif (${ModeType.Equal[NOCOLORSALLOWED]})
        {
        	  if (${Toggle.Equal[TRUE]})
        	   		echo [${User}] ${Channel} has been designated as NO COLORS ALLOWED by ${WhoSet}
        	  else
        	      echo [${User}] ${WhoSet} has removed the NO COLORS ALLOWED flag from ${Channel}
        }
    }
    
    member:bool Connected()
    {
        if ${IRC.NumUsers} > 0
            return TRUE
            
        return FALSE
    }
     
    function Connect() 
    {       
        IRC:Connect[${Config.Common.IRCServer},${Config.Common.IRCUser}]
               
        wait 10 
                                
        IRCUser[${Config.Common.IRCUser}]:Join[${Config.Common.IRCChannel}]
               
        wait 10                 
        This.IsConnected:Set[TRUE]
        wait 10 
                                
        Call This.Say "Reporting for duty, sir"
    } 
                       
    function Disconnect() 
    {           
        if ${This.IsConnected} 
        {       
            echo DEBUG: Disconnecting...
            Call This.Say "Disconnecting as Ordered, sir"
            wait 10 
                            
            IRCUser[${Config.Common.IRCUser}]:Disconnect
            This.IsConnected:Set[FALSE]
        } 
    } 
    
    function Say(string msg)
    {       
        ;echo Connected? ${This.IsConnected}
        if ${This.IsConnected} 
        {       
            IRCUser[${Config.Common.IRCUser}].Channel[${Config.Common.IRCChannel}]:Say["${msg}"]
        } 
        else
        {
            call This.Connect
        }
    }      
} 