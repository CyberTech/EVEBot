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

        private Dictionary<ListViewItem, Client> _clientTable = new Dictionary<ListViewItem,Client>();
        private List<string> _clientProperties;
        public ClientsWindow()
        {
            InitializeComponent();
            _clientProperties = new List<string>();
             Type type = typeof(Client);
            foreach (PropertyInfo propertyInfo in type.GetProperties())
            {
                _clientProperties.Add(propertyInfo.Name);
                listView1.Columns.Add(propertyInfo.Name);
            }
        }
        public void AddClient(Client client)
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
        public void UpdateClient(Client Client)
        {
            if (listView1.Items.ContainsKey(Client.Name))
            {
                _clientTable[listView1.Items[Client.Name]] = Client;
            }
            else
            {
                AddClient(Client);
            }
            this.Invalidate();
        }
        public void UpdateClients()
        {
            foreach (ListViewItem lvi in listView1.Items)
            {
                lvi.SubItems["ArmorPct"].Text = _clientTable[lvi].ArmorPct.ToString();
                lvi.SubItems["ShieldPct"].Text = _clientTable[lvi].ShieldPct.ToString();
                lvi.SubItems["CapacitorPct"].Text = _clientTable[lvi].CapacitorPct.ToString();
            }
            listView1.AutoResizeColumns(ColumnHeaderAutoResizeStyle.ColumnContent);
        }

        private void ClientsWindow_Paint(object sender, PaintEventArgs e)
        {
            UpdateClients();
        }
                
    }
}