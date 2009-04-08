using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using LavishScriptAPI;
using LavishVMAPI;


namespace EveBots
{
    public partial class MainInterface : Form
    {
        protected ClientsWindow _clientsWindow = new ClientsWindow();
        protected LauncherProfiles _launcherProfiles = new LauncherProfiles();
        public MainInterface()
        {
            InitializeComponent();
            LavishScript.Commands.AddCommand("UpdateClient",ClientCallback);
            this.panel1.Controls.Add(_clientsWindow);

        }
        public int ClientCallback(string[] args)
        {
            Client newClient = new Client();
            for (int i = 0; i < args.Length; i++)
            {
                switch (i)
                {
                    case 1:
                        {
                            LavishScript.ExecuteCommand("echo Parameter number : " + i + " = " + args[i]);
                            newClient.Name = args[i];
                            break;
                        }
                    case 2:
                        {
                            LavishScript.ExecuteCommand("echo Parameter number : " + i + " = " + args[i]);
                            newClient.ShieldPct = (int)float.Parse(args[i]);
                            break;
                        }
                    case 3:
                        {
                            LavishScript.ExecuteCommand("echo Parameter number : " + i + " = " + args[i]);
                            newClient.ArmorPct = (int)float.Parse(args[i]);
                            break;
                        }
                    case 4:
                        {
                            LavishScript.ExecuteCommand("echo Parameter number : " + i + " = " + args[i]);
                            newClient.CapacitorPct = (int)float.Parse(args[i]);
                            break;
                        }
                }
            }
            _clientsWindow.UpdateClient(newClient);
            return 1;
        }

        public int UpdateClient(string[] args)
        {
            
            this.Invalidate();
                return 1;
                
        }

 
    }
}
