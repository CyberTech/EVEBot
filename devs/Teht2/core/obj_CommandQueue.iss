/*
	Sound class
	
	Object to handle playing sounds.
	
	-- GliderPro
	
*/

objectdef obj_Command
{
	variable string Object
	variable string Method
	variable string Args

	method Initialize(string arg_Object, string arg_Method, string arg_Args)
	{
		Object:Set[${arg_Object}]
		Method:Set[${arg_Method}]
		Args:Set["${arg_Args.Escape}"]
	}
}

objectdef obj_CommandQueue
{
	variable string SVN_REVISION = "$Rev: 1897 $"
	variable int Version
	
	variable queue:obj_Command Commands

	;	Pulse tracking information
	variable int NextPulse
	variable int PulseIntervalInMilliseconds = 2000
	
	method Initialize()
	{
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]

		UI:UpdateConsole["obj_CommandQueue: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
	}	

	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

	    if ${LavishScript.RunningTime} >= ${This.NextPulse}
		{
			This:ProcessCommands[]

    		This.NextPulse:Set[${Math.Calc[${LavishScript.RunningTime} + ${PulseIntervalInMilliseconds} + ${Math.Rand[500]}]}]
		}
	}	

	
	;	Processes one command if the queue is not empty
	method ProcessCommands()
	{
		if ${Commands.Used} == 0
		{
			return
		}
		
		
		if ${Commands.Peek(exists)}
		{
			echo ${Commands.Peek.Object}:${Commands.Peek.Method}  Args - ${Commands.Peek.Args}
			if ${Commands.Peek.Object.Equal[IGNORE]}
			{
				Commands:Dequeue
				return
			}
			if ${Commands.Peek.Object.Equal[WAITSPACE]}
			{
				if ${Me.InSpace}
				{
					Commands:Dequeue
				}
				return
			}
			if ${Commands.Peek.Method.Equal[DockAtStation]}
			{
				if ${Me.InStation}
				{
					Commands:Dequeue
				}
				else
				{
					${Commands.Peek.Object}:${Commands.Peek.Method}[${Commands.Peek.Args}]
					This:InsertCommand[IGNORE]
					This:InsertCommand[IGNORE]
					This:InsertCommand[IGNORE]
					This:InsertCommand[IGNORE]
					This:InsertCommand[IGNORE]
					This:InsertCommand[IGNORE]
					This:InsertCommand[IGNORE]
					This:InsertCommand[IGNORE]
				}
				return
			}
			if ${Commands.Peek.Method.Equal[Undock]}
			{
				if ${Me.InSpace}
				{
					Commands:Dequeue
				}
				else
				{
					${Commands.Peek.Object}:${Commands.Peek.Method}[${Commands.Peek.Args}]
					This:InsertCommand[IGNORE]
				}
				return
			}			
			${Commands.Peek.Object}:${Commands.Peek.Method}[${Commands.Peek.Args}]
			Commands:Dequeue
		}

		
	}
	method InsertCommand(string arg_Object, string arg_Method="", string arg_Args="")
	{
		variable queue:obj_Command TempQueue
		TempQueue:Queue[${arg_Object},${arg_Method},"${arg_Args.Escape}"]
		if ${Commands.Peek(exists)}
		do
		{
			TempQueue:Queue[${Commands.Peek.Object},${Commands.Peek.Method},${Commands.Peek.Args}]
			Commands:Dequeue
		}
		while ${Commands.Peek(exists)}
		if ${TempQueue.Peek(exists)}
		do
		{
			Commands:Queue[${TempQueue.Peek.Object},${TempQueue.Peek.Method},${TempQueue.Peek.Args}]
			TempQueue:Dequeue
		}
		while ${TempQueue.Peek(exists)}
	}
	method QueueCommand(string arg_Object, string arg_Method="", string arg_Args="")
	{
		Commands:Queue[${arg_Object},${arg_Method},"${arg_Args.Escape}"]
	}
	
	member:int Queued()
	{
		return ${Commands.Used}
	}
	
	method Clear()
	{
		Commands:Clear
	}
}
