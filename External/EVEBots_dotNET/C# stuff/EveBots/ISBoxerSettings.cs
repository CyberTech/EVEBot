using System;
using System.Collections.Generic;
using System.Text;
using LavishSettingsAPI;

namespace EveBots
{
    class ISBoxerSettings
    {
        private LavishSettings _lavishSettings = new LavishSettings();
        private string _homeDirectory = InnerSpaceAPI.InnerSpace.Path.Replace('\\', '/') + "/Scripts";
        private Set _characters_Set;
        private Set _characterSets_Set;
        private Dictionary<string, CharacterSet> _characterSets = new Dictionary<string,CharacterSet>();
        public Dictionary<string, CharacterSet> CharacterSets
        {
            get
            {
                return _characterSets;
            }
        }
        public ISBoxerSettings()
        {
            _lavishSettings.Tree.Import(_homeDirectory + "/ISBoxerToolkit.GeneralSettings.XML");
            _characters_Set = _lavishSettings.Tree.FindSet("Characters");
            _characterSets_Set = _lavishSettings.Tree.FindSet("Character Sets");
            InnerSpaceAPI.InnerSpace.Echo(_homeDirectory + "/ISBoxerToolkit.GeneralSettings.XML");
            BuildCharSets();
        }
        private void BuildCharSets()
        {
            LavishScriptAPI.LavishScriptIterator charsetIterator = _characterSets_Set.GetSetIterator();

            if (charsetIterator.IsValid)
            {
                charsetIterator.First();
                do
                {
                    Set charSet_Set = new Set(charsetIterator.GetPersistentMember("Value"));
                    CharacterSet charset = new CharacterSet(charSet_Set.Name);
                    
                    LavishScriptAPI.LavishScriptIterator slotIterator = charSet_Set.FindSet("Slots").GetSetIterator();
                    if (slotIterator.IsValid)
                    {
                        charsetIterator.First();
                        do
                        {
                            Set characterSlot_Set = new Set(slotIterator.GetPersistentMember("Value"));
                            Character newChar = new Character(characterSlot_Set.FindSetting("Character").ToString());
                            charset.AddCharacter(newChar);
                            slotIterator.Next();
                        }
                        while (slotIterator.IsValid);
                    }
                    _characterSets.Add(charset.CharSetName, charset);
                    charsetIterator.Next();
                }
                while (charsetIterator.IsValid);
            }
        }
    }
    public class CharacterSet
    {
        Dictionary<string, Character> _characters = new Dictionary<string, Character>();
        string _setName = "-";
        public CharacterSet(string name)
        {
            _setName = name;
        }
        public void AddCharacter(Character character)
        {
            _characters.Add(character.Session.Name, character);
        }
        public string CharSetName
        {
            get
            {
                return _setName;
            }
        }
        public Dictionary<string, Character> Characters
        {
            get
            {
                return _characters;
            }
        }
    }

    public class Character
    {
        string _name;
        Session _session;
        public Character(string name)
        {
            _session = new Session(name);
        }
        public Session Session
        {
            get
            {
                return _session;
            }
        }

    }
}

