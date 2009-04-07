using System;
using System.Collections.Generic;
using System.Text;

namespace EveBots
{
    public class Client
    {
        private int _armorPct = 0;
        private int _shieldPct = 0;
        private int _capacitorPct = 0;
        private string _name = "default";
        private ClientStatus _status = ClientStatus.Inactive;
        public Client(string Name, ClientStatus Status)
        {
            _name = Name;
            _status = Status;
        }
        public Client()
        {

        }
        public void UpdateStatus(ClientStatus Status)
        {
            _status = Status;
        }
        public void UpdatePct(int ArmorPct,int ShieldPct,int CapacitorPct)
        {
            _armorPct = ArmorPct;
            _shieldPct = ShieldPct;
            _capacitorPct = CapacitorPct;
        }
        public string Name
        {
            get
            {
                return _name;
            }
            set
            {
                _name = value;
            }
        }
        public int ArmorPct
        {
            get
            {
                return _armorPct;
            }
            set
            {
                _armorPct = value;
            }
        }
        public int ShieldPct
        {
            get
            {
                return _shieldPct;
            }
            set
            {
                _shieldPct = value;
            }
        }
        public int CapacitorPct
        {
            get
            {
                return _capacitorPct;
            }
            set
            {
                _capacitorPct = value;
            }
        }
      
    }
    public enum ClientStatus
    {
        Active,
        Inactive,
        Late,
        Dead,
        Fleeing
    }
}
