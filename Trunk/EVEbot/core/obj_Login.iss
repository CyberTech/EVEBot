

function main()
{
	declare EveOnline_UserName	string	script	"username"
	declare EveOnline_PassWord	string	script	"password"

	if !${ISXEVE(exists)}
		call LoadISXEVE

	while ${Login.Serverstatus.NotEqual[LIVE]}
		wait 3000

	Login:SetUsername[${EveOnline_UserName}]
	wait 10
	Login:SetPassword[${EveOnline_PassWord}]
	wait 10
	Login:Connect
	wait 10
	
	while !${CharSelect(exists)}
		wait 50
	
	if ${CharSelect(exists)}
		CharSelect:ClickCharacter

	while !${Me.Name(exists)}
		wait 50

	run evebot/evebot
}

function LoadISXEVE()
{
	  variable int Timer = 0

	  if (${ISXEVE(exists)})
	    return
	    
	  echo off  
	  do
	  {   
	  	wait 15
	    if (${ISXEVE.IsLoading})
	      return
	  	if (${ISXEVE.IsReady})
	  	  return
	  	
	  	extension isxeve
	    Timer:Set[0]
	    
	    if (${ISXEVE.IsLoading})
	      return
	    
	    do
	    {
	       if (${ISXEVE.IsLoading})
	           return
	           
	       Timer:Inc
	       waitframe
	    }
	    while (!${ISXEVE(exists)} && ${Timer} < 100)
	  }
	  while (!${ISXEVE(exists)})
}