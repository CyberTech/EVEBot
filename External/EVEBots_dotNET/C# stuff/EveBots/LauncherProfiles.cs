using System;
using System.Collections.Generic;
using System.Text;
using LavishSettingsAPI;
namespace EveBots
{
    public class LauncherProfiles
    {
        private LavishSettings _lavishSettings = new LavishSettings();
        private Set _gameConfigurationXMLSet;
        private Set _profilesSet;
        private List<Profile> _profileList = new List<Profile>();
        private string _homeDirectory = InnerSpaceAPI.InnerSpace.Path.Replace('\\', '/');
        public LauncherProfiles()
        {
            // <Lax>   ${LavishSettings[${LavishScript.HomeDirectory}/GameConfiguration.XML]}
            //<Lax> but needs \ converted to /

            _gameConfigurationXMLSet = _lavishSettings.Tree.FindSet((_homeDirectory + "/GameConfiguration.XML"));
            _profilesSet = _gameConfigurationXMLSet.FindSet("EVE Online").FindSet("Profiles");
            LavishScriptAPI.LavishScriptIterator profilesIterator = _profilesSet.GetSetIterator();

            if (profilesIterator.IsValid)
            {
                profilesIterator.First();
                do
                {
                    _profileList.Add(new Profile(new Set(profilesIterator.GetPersistentMember("Value")),_profilesSet));
                    profilesIterator.Next();
                }
                while (profilesIterator.IsValid);
            }
        }
        public Profile AddProfile(string ProfileName, string Path, string Executable, Dictionary<string, string> StartupSequence)
        {
            Profile p = new Profile(ProfileName, Path, Executable, StartupSequence, _profilesSet);
            _profileList.Add(p);
            return p;
        }
        public void DeleteProfile(string ProfileName)
        {
            foreach (Profile p in _profileList)
            {
                if (p.ProfileName.Equals(ProfileName))
                {
                    p.DeleteProfile();
                    _profileList.Remove(p);
                    break;
                }
            }
        }
        public void Save()
        {
            foreach (Profile p in _profileList)
            {
                p.SaveProfile();
            }
            _gameConfigurationXMLSet.Export(_homeDirectory + "/GameConfiguration.XML");
        }
        public List<Profile> Profiles
        {
            get
            {
                return _profileList;
            }
        }
       

    }
    public class Profile
    {
        private string _profileName;
        private string _path;
        private string _executable;
        private Set _setReference;
        private Set _parentSet;
        private Dictionary<string, string> _startupSequence = new Dictionary<string, string>();

        public Profile(Set ProfileSet, Set ProfileParentSet)
        {
            _profileName = ProfileSet.Name;
            _path = ProfileSet.FindSetting("Path").ToString();
            _executable = ProfileSet.FindSetting("Executable").ToString();
            _setReference = ProfileSet;
            _parentSet = ProfileParentSet;

            LavishScriptAPI.LavishScriptIterator startUpIterator = ProfileSet.FindSet("Startup Sequence").GetSettingIterator();
            
            if (startUpIterator.IsValid)
            {
                startUpIterator.First();
                do
                {
                    Setting setting = new Setting(startUpIterator.GetPersistentMember("Value"));
                    _startupSequence.Add(setting.Name, setting.ToString());
                    startUpIterator.Next();                
                }
                while (startUpIterator.IsValid);
            }
        }
        public Profile(string ProfileName, string Path, string Executable, Dictionary<string, string> StartupSequence, Set ProfileParentSet)
        {
            _profileName = ProfileName;
            _path = Path;
            _executable = Executable;
            _startupSequence = StartupSequence;
            _parentSet = ProfileParentSet;
        }
        public void SaveProfile()
        {
            if (_setReference != null)
            {
                _setReference.FindSetting("Path").Set(_path);
                _setReference.FindSetting("Executable").Set(_executable);
                _setReference.FindSet("Startup Sequence").Remove();
                _setReference.AddSet("Startup Sequence");
                foreach (string sequencename in _startupSequence.Keys)
                {
                    _setReference.FindSet("Startup Sequence").AddSetting(sequencename, _startupSequence[sequencename]);
                }
            }
            else
            {
                _parentSet.AddSet(_profileName);
                _setReference = _parentSet.FindSet(_profileName);
                _setReference.AddSetting("Path", _path);
                _setReference.AddSetting("Executable", _executable);
                _setReference.AddSet("Startup Sequence");
                foreach (string sequencename in _startupSequence.Keys)
                {
                    _setReference.FindSet("Startup Sequence").AddSetting(sequencename, _startupSequence[sequencename]);
                }
            }
        }
        public void DeleteProfile()
        {
            if (_setReference != null)
            {
                _setReference.Remove();
                _setReference = null;
            }
        }
        public string ProfileName
        {
            get
            {
                return _profileName;
            }
            set
            {
                _profileName = value;
            }
        }
        public string Path
        {
            get
            {
                return _path;
            }
            set
            {
                _path = value;
            }
        }
        public string Executable
        {
            get
            {
                return _executable;
            }
            set
            {
                _executable = value;
            }
        }
        public Dictionary<string, string> StartUpSequence
        {
            get
            {
                return _startupSequence;
            }
            set
            {
                _startupSequence = value;
            }
        }
    }
}
