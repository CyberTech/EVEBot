/*
	Defines methods for dynamically populating LSGUI elements from script, 
	by allowing single-line calls to methods, rather than embedding XML 
	into all the source files.
	
	Note: IF you edit this, be sure to note the embedded \n inside the 
	emebedded lavishscript inside the XML
	
	-- CyberTech (cybertech@gmail.com)
*/
objectdef obj_LSGUI inherits obj_BaseClass
{
	variable string SVN_REVISION = "$Rev$"
	variable string SVN_PATH = "$HeadURL: http://www.isxgames.com/isxScripts/isxGamesCommon/CyberTech/obj_PulseTimer.iss $"
	variable string SVN_AUTHOR = "$Author$"
	
	method CreateCheckBox(string _Location, string _Name, int _X, int _Y, int _Height, int _Width, string _ObjectName, string _VarName, string _Text, string _Tooltip="")
	{
		UIElement[${_Location}]:AddChild[checkbox, ${_Name}, " \
			<checkbox Name='${_Name}'> \
				<X>${_X}</X> \
				<Y>${_Y}</Y> \
				<Height>${_Height}</Height> \
				<Width>${_Width}</Width> \
				<Text>${_Text}</Text> \
				<AutoTooltip>${_Tooltip}</AutoTooltip> \
				<OnLoad> \
					if \${${_ObjectName}.${_VarName}} \n\
					{ \n\
						This\:SetChecked \n\
					} \n\
				</OnLoad> \
				<OnLeftClick> \
					${_ObjectName}\:${_VarName}[\${This.Checked}] \n\
				</OnLeftClick> \
			</checkbox> \
		", "eveskin"]
	}
}