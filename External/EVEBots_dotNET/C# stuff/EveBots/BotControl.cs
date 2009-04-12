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
        ISBoxerSettings _ISBoxerSettings = new ISBoxerSettings();
        Dictionary<string, CharacterSet> _charSets = new Dictionary<string, CharacterSet>();
        public BotControl()
        {
            InitializeComponent();
            LavishScript.Commands.AddCommand("UpdateClient", ClientCallback);
            this.PopulateCharSets();
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
            if (args.Length == 12)
            {
                foreach (CharacterSet charset in _charSets.Values)
                {
                    if (charset.Characters.ContainsKey(args[1]))
                    {                        
                        charset.Characters[args[1]].Session.Update((int)float.Parse(args[2]),(int)float.Parse(args[3]),(int)float.Parse(args[4]),bool.Parse(args[5]),args[6],args[7],bool.Parse(args[8]),args[9],args[10],args[11]);
                    }
                }
                clientsWindow1.UpdateClients();
                return 1;
            }
            else
            {
                return -1;
            }
            
        }
    }
}
