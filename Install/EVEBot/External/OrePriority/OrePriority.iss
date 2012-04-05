function main()
{
	if !${Script[evebot](exists)}
	{
		echo Error: OrePriority requires EVEBot to be running.
		return
	}
	ui -load "${Script.CurrentDirectory}/OrePriorityUI.xml"
	while ${UIElement[OrePriority].Visible} && ${Script[evebot](exists)}
		wait 1
}
function atexit()
{
	if ${UIElement[OrePriority](exists)}
		UIElement[OrePriority]:Destroy
}
