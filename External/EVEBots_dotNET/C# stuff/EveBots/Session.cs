using System;
using System.Collections.Generic;
using System.Text;

namespace EveBots
{
    public class Session
    {
        private string _sessionName = "-";
        private TimeSpan _late = new TimeSpan(0, 0, 10);
        private TimeSpan _timeOut = new TimeSpan(0, 0, 20);
        private int _armorPct = 0;
        private int _shieldPct = 0;
        private int _capacitorPct = 0;
        private DateTime _lastUpdate = DateTime.Now;
        private bool _calledBack = false;
        private bool _launched = false;
        private string _name = "-";
        private bool _hide = false;
        private string _hideReason = "-";
        private string _currentTarget = "-";
        private bool _paused = false;
        private string _botMode = "-";
        private string _ship= "-";
        private int _crashes = 0;
       
        public Session(string name)
        {
            _name = name;
        }
        public void Update(int ArmorPct,int ShieldPct,int CapacitorPct,bool Hiding,string HidingReason,string CurrentTarget,bool Paused,string BotMode,string Ship, string SessionName)
        {
            _armorPct = ArmorPct;
            _shieldPct = ShieldPct;
            _capacitorPct = CapacitorPct;
            _hide = Hiding;
            _hideReason = HidingReason;
            _currentTarget = CurrentTarget;
            _paused = Paused;
            _botMode = BotMode;
            _lastUpdate = DateTime.Now;
            _calledBack = true;
            _launched = true;
            _ship = Ship;
            _sessionName = SessionName;
        }
        public void Launch()
        {
            _calledBack = false;
            _launched = true;
        }
        public string Name
        {
            get
            {
                return _name;
            }          
        }
        public int ArmorPct
        {
            get
            {
                return _armorPct;
            }           
        }
        public int ShieldPct
        {
            get
            {
                return _shieldPct;
            }            
        }
        public int CapacitorPct
        {
            get
            {
                return _capacitorPct;
            }            
        }
        public string Currentarget
        {
            get
            {
                return _currentTarget;
            }
        }
        public SessionStatus Status
        {
            get
            {
                if (_launched)
                {
                    if (_calledBack)
                    {
                        if (_lastUpdate.Add(_timeOut).CompareTo(DateTime.Now) < 0)
                        {
                            return SessionStatus.TimedOut;
                        }
                        if (_lastUpdate.Add(_late).CompareTo(DateTime.Now) < 0)
                        {
                            return SessionStatus.Late;
                        }
                        if (_paused)
                        {
                            return SessionStatus.Paused;
                        }
                        if (_hide)
                        {
                            return SessionStatus.Fleeing;
                        }
                        if (_shieldPct < 10)
                        {
                            return SessionStatus.InTrouble;
                        }
                        return SessionStatus.Active;
                    }
                    else
                    {
                        return SessionStatus.Launching;
                    }
                }
                else
                {
                    return SessionStatus.NotLaunched;
                }
            }
        }
        public bool Launched
        {
            get
            {
                return _launched;
            }
            set
            {
                _launched = value;
            }
        }
        public bool Hiding
        {
            get
            {
                return _hide;
            }
        }
        public string BotMode
        {
            get
            {
                return _botMode;
            }
        }
        public string Ship
        {
            get
            {
                return _ship;
            }
        }
        public int Crashes
        {
            get
            {
                return _crashes;
            }
            set
            {
                _crashes = value;
            }
        }
        public DateTime LastUpdate
        {
            get
            {
                return _lastUpdate;
            }
        }
        public string SessionName
        {
            get
            {
                return _sessionName;
            }
        }
      
    }
    public enum SessionStatus
    {
        NotLaunched,
        Launching,
        Paused,
        Active,
        InTrouble,
        Fleeing,
        Late,
        TimedOut
    }
}
