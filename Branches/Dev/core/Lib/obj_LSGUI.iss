/*
	Defines methods for dynamically populating LSGUI elements from script,
	by allowing single-line calls to methods, rather than embedding XML
	into all the source files.

	Note: IF you edit this, be sure to note the embedded \n inside the
	emebedded lavishscript inside the XML. It's required.

	Initialize accepts the root path to the UIElement we're managing, for callees to access as LSGUI.Root

	Currently implemented LavishGUI objects:
		Tab
		Children
		ListBox
		Text
		Button

	-- CyberTech (cybertech@gmail.com)
*/
objectdef obj_LSGUI inherits obj_BaseClass
{
	variable string Root = ""
	variable string SkinName = "eveskin"

	method Initialize(string _Base)
	{
		Root:Set[${_Base}]
	}

	method AddTab(string _TabName, string _Location)
	{
		UIElement[${_Location}]:AddTab[${_TabName}]
	}

	method RemoveTab(string _TabName)
	{
		UIElement[${_TabName}]:Remove
	}

	method CreateChildren(string _Name, string _Location)
	{
		UIElement[${_Location}]:AddChild["children", ${_Name}, " \
			<children Name='${_Name}'> \
			</children> \
		", "${SkinName}"]
	}

	method CreateText(string _Location, string _Name, int _X, int _Y, int _Height, int _Width, string _Text)
	{
		UIElement[${_Location}]:AddChild["text", ${_Name}, " \
			<Text name='${_Name}'> \
				<X>${_X}</X> \
				<Y>${_Y}</Y> \
				<Height>${_Height}</Height> \
				<Width>${_Width}</Width> \
				<Text>${_Text}</Text> \
			</Text> \
		", "${SkinName}"]
	}

	method CreateCheckBox(string _Location, string _Name, int _X, int _Y, int _Height, int _Width, string _ObjectName, string _VarName, string _Text, string _Tooltip="")
	{
		UIElement[${_Location}]:AddChild["checkbox", ${_Name}, " \
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
		", "${SkinName}"]
	}

	method CreateListBox(string _Location, string _Name, int _X, int _Y, int _Height, int _Width, int _SelectMultiple, string _Sort)
	{
		UIElement[${_Location}]:AddChild["listbox", ${_Name}, " \
			<listbox name='${_Name}'> \
				<X>${_X}</X> \
				<Y>${_Y}</Y> \
				<Height>${_Height}</Height> \
				<Width>${_Width}</Width> \
				<SelectMultiple>${_SelectMultiple}</SelectMultiple> \
				<Sort>${_Sort}</Sort> \
				<Texture filename='Listbox.png'/> \
				<Items> \
				</Items> \
			</listbox> \
		", "${SkinName}"]
	}

	method CreateButton(string _Location, string _Name, int _X, int _Y, int _Height, int _Width, string _Text, string _OnLeftClick)
	{
		UIElement[${_Location}]:AddChild["button", ${_Name}, " \
			<button name='${_Name}'> \
				<X>${_X}</X> \
				<Y>${_Y}</Y> \
				<Height>${_Height}</Height> \
				<Width>${_Width}</Width> \
				<Text>${_Text}</Text> \
				<OnLeftClick> \
					${_OnLeftClick.Escape} \
				</OnLeftClick> \
			</button> \
		", "${SkinName}"]
	}
}
