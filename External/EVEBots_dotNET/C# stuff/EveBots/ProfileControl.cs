using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Text;
using System.Windows.Forms;

namespace EveBots
{
    public partial class ProfileControl : UserControl
    {
        LauncherProfiles _lProfiles;
        Dictionary<string,Profile> _pList = new Dictionary<string,Profile>();
        public ProfileControl()
        {
            InitializeComponent();
            _lProfiles = new LauncherProfiles();
            foreach (Profile p in _lProfiles.Profiles)
            {
                _pList.Add(p.ProfileName, p);
            }
            UpdateProfileTree();
            _pSequence.Columns.Add("Command");
        }
        private void UpdateProfileTree()
        {
            foreach (Profile p in _pList.Values)
            {
                treeView1.Nodes.Add(p.ProfileName, p.ProfileName);
            }
        }

        private void _addProfile_Click(object sender, EventArgs e)
        {
            Profile p = _lProfiles.AddProfile("New Profile", "executable location", "executable name", new Dictionary<string, string>());
            _pList.Add(p.ProfileName, p);
            TreeNode tn = new TreeNode();
            tn.Name = p.ProfileName;
            tn.Text = p.ProfileName;
            treeView1.Nodes.Add(tn);
            treeView1.SelectedNode = tn;
        }

        private void _removeProfile_Click(object sender, EventArgs e)
        {
            _lProfiles.DeleteProfile(treeView1.SelectedNode.Name);
            treeView1.SelectedNode.Remove();
        }

        private void _Finished_Click(object sender, EventArgs e)
        {
            _lProfiles.Save();
            this.Hide();
        }

       

        private void treeView1_AfterSelect(object sender, TreeViewEventArgs e)
        {
            _pName.Text = _pList[treeView1.SelectedNode.Name].ProfileName;
            _pPath.Text = _pList[treeView1.SelectedNode.Name].Path;
            _pExecutable.Text = _pList[treeView1.SelectedNode.Name].Executable;
            NewSequenceList(_pList[treeView1.SelectedNode.Name].StartUpSequence);
        }
        private void NewSequenceList(Dictionary<string, string> SequenceList)
        {
            foreach (string name in SequenceList.Keys)
            {
                _pSequence.Items.Clear();
                ListViewItem lvi = new ListViewItem(SequenceList[name]);
                lvi.Name = name;
                _pSequence.Items.Add(lvi);
            }
            foreach (ColumnHeader cH in _pSequence.Columns)
            {
                cH.AutoResize(ColumnHeaderAutoResizeStyle.ColumnContent);
            }
        }

        private void _pSequence_BeforeLabelEdit(object sender, LabelEditEventArgs e)
        {
           Dictionary<string,string> sequenceList = _pList[treeView1.SelectedNode.Name].StartUpSequence;
           sequenceList[_pSequence.Items[e.Item].Name] = e.Label;
        }

        private void _pPath_TextChanged(object sender, EventArgs e)
        {
            _pList[treeView1.SelectedNode.Name].Path = _pPath.Text;
        }

        private void _pExecutable_TextChanged(object sender, EventArgs e)
        {
            _pList[treeView1.SelectedNode.Name].Executable = _pExecutable.Text;
        }
        private void _pName_TextChanged(object sender, EventArgs e)
        {
            _pList[treeView1.SelectedNode.Name].ProfileName = _pName.Text;
            treeView1.SelectedNode.Text = _pName.Text;
            treeView1.SelectedNode.Name = _pName.Text;
        }
      
    }
}
