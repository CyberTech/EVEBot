using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Text;
using System.Windows.Forms;
using System.Reflection;

namespace EveBots
{
    public partial class ClientsWindow : UserControl
    {
        private int _clientCount;

        private Dictionary<ListViewItem, Session> _clientTable = new Dictionary<ListViewItem,Session>();
        private List<string> _clientProperties;
        public ClientsWindow()
        {
            InitializeComponent();
            _clientProperties = new List<string>();
             Type type = typeof(Session);
            foreach (PropertyInfo propertyInfo in type.GetProperties())
            {
                _clientProperties.Add(propertyInfo.Name);
                listView1.Columns.Add(propertyInfo.Name);
            }
        }
        public void AddClient(Session client)
        {
            _clientCount++;
            ListViewItem newClient = new ListViewItem();
            foreach (string propertyName in _clientProperties)
            {
                if (propertyName.Equals("Name"))
                {
                    newClient.Name = client.Name;
                    newClient.Text = client.Name;
                }
                else
                {
                    System.Windows.Forms.ListViewItem.ListViewSubItem subItem = new ListViewItem.ListViewSubItem();
                    subItem.Name = propertyName;
                    subItem.Text = "-";
                    newClient.SubItems.Add(subItem);
                }
            }
            listView1.BeginUpdate();
            listView1.Items.Add(newClient);
            listView1.EndUpdate();
            _clientTable.Add(newClient, client);
        }
        public void UpdateClients()
        {
            listView1.BeginUpdate();
            foreach (ListViewItem lvi in listView1.Items)
            {
                lvi.Text = _clientTable[lvi].Name;
                lvi.SubItems["ArmorPct"].Text = _clientTable[lvi].ArmorPct.ToString();
                lvi.SubItems["ShieldPct"].Text = _clientTable[lvi].ShieldPct.ToString();
                lvi.SubItems["CapacitorPct"].Text = _clientTable[lvi].CapacitorPct.ToString();
                lvi.SubItems["Launched"].Text = _clientTable[lvi].Launched.ToString();
                lvi.SubItems["Hiding"].Text = _clientTable[lvi].Hiding.ToString();
                lvi.SubItems["BotMode"].Text = _clientTable[lvi].BotMode;
                lvi.SubItems["Ship"].Text = _clientTable[lvi].Ship;
                lvi.SubItems["Crashes"].Text = _clientTable[lvi].Crashes.ToString();
                lvi.SubItems["LastUpdate"].Text = _clientTable[lvi].LastUpdate.ToLongTimeString();
                lvi.Text = _clientTable[lvi].Name;
                lvi.Name = _clientTable[lvi].Name;
                lvi.SubItems["Status"].Text = _clientTable[lvi].Status.ToString();
            }
            listView1.AutoResizeColumns(ColumnHeaderAutoResizeStyle.ColumnContent);
            listView1.EndUpdate();
        }

        private void ClientsWindow_Paint(object sender, PaintEventArgs e)
        {
            UpdateClients();
        }
                
    }
}