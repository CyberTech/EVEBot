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
        protected ProfileControl _profileControl = new ProfileControl();

        public MainInterface()
        {
            InitializeComponent();

            this.panel1.Controls.Add(_profileControl);
            _profileControl.Dock = DockStyle.Fill;

        }
       

        public int UpdateClient(string[] args)
        {
            
            this.Invalidate();
                return 1;
                
        }

 
    }
}
