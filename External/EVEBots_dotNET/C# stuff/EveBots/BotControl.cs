using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Text;
using System.Windows.Forms;
using LavishScriptAPI;

namespace EveBots
{
    public partial class BotControl : UserControl
    {
        Timer _updateBotsTimer = new Timer();
        ISBoxerSettings _ISBoxerSettings = new ISBoxerSettings();
        Dictionary<string, CharacterSet> _charSets = new Dictionary<string, CharacterSet>();
        public BotControl()
        {
            InitializeComponent();
            LavishScript.Commands.AddCommand("UpdateClient", ClientCallback);
            this.PopulateCharSets();
            _updateBotsTimer.Tick += new EventHandler(_updateBotsTimer_Tick);
            _updateBotsTimer.Interval = 2000;
            _updateBotsTimer.Start();
        }

        void _updateBotsTimer_Tick(object sender, EventArgs e)
        {
            foreach (CharacterSet charSet in _charSets.Values)
            {
                foreach (Character character in charSet.Characters.Values)
                {
                    if (character.Session.Status == SessionStatus.NotLaunched && charSet.Launched)
                    {
                        InnerSpaceAPI.InnerSpace.Echo("launching charset " + charSet.CharSetName);
                        LavishScript.ExecuteCommand("run isboxer -launch " + charSet.CharSetName);
                        character.Session.Launch();
                    }                    
                    if (character.Session.Status == SessionStatus.TimedOut)
                    {
                        LavishScript.ExecuteCommand("kill " + character.Session.SessionName);
                        InnerSpaceAPI.InnerSpace.Echo("killing session " + character.Session.SessionName);
                        character.Session.Launched = false;
                        character.Session.Crashes++;
                    }
                }
            }
            clientsWindow1.UpdateClients();
        }
        private void PopulateCharSets()
        {
            _charSets = _ISBoxerSettings.CharacterSets;
            foreach (CharacterSet charSet in _charSets.Values)
            {
                TreeNode newNode = new TreeNode(charSet.CharSetName);
                newNode.Name = charSet.CharSetName;
                charSetTView.Nodes.Add(newNode);
            }

        }

        private void charSetTView_AfterSelect(object sender, TreeViewEventArgs e)
        {
            foreach (Character character in _charSets[charSetTView.SelectedNode.Name].Characters.Values)
            {
                clientsWindow1.AddClient(character.Session);
            }
        }
        private int ClientCallback(string[] args)
        {
            InnerSpaceAPI.InnerSpace.Echo("GOT CALLBACK");
            if (args.Length == 12)
            {
                InnerSpaceAPI.InnerSpace.Echo("CORRECT NUMBER OF ARGS");
                foreach (string s in args)
                {
                    InnerSpaceAPI.InnerSpace.Echo(s);
                }
                foreach (CharacterSet charset in _charSets.Values)
                {
                    if (charset.Characters.ContainsKey(args[1]))
                    {
                        InnerSpaceAPI.InnerSpace.Echo("UPDATIN SESH");                        
                        charset.Characters[args[1]].Session.Update((int)float.Parse(args[2]),(int)float.Parse(args[3]),(int)float.Parse(args[4]),bool.Parse(args[5]),args[6],args[7],bool.Parse(args[8]),args[9],args[10],args[11]);
                    }
                }
                InnerSpaceAPI.InnerSpace.Echo("FORCING CLIENTWINDOW TO UPDATE");
                clientsWindow1.UpdateClients();
                return 1;
            }
            else
            {
                return -1;
            }
            
        }

        private void button1_Click(object sender, EventArgs e)
        {            
            if (charSetTView.SelectedNode != null)
            {
                InnerSpaceAPI.InnerSpace.Echo("MUST LAUNCH");
                _charSets[charSetTView.SelectedNode.Name].Launched = true;
            }
        }
    }
}
