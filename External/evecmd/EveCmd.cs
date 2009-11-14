using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using LavishScriptAPI;
using LavishVMAPI;
using InnerSpaceAPI;
using EVE.ISXEVE;

namespace evecmd
{
    class EveCmd
    {
        private static object lock_ = new object();
        private static List<string> command_queue_ = new List<string>();
        List<State> states = new List<State>();

        static void Main(string[] args)
        {
            new EveCmd().Run();
        }

        public void Initialize()
        {
            if (g.eve == null)
            {
                g.eve = new EVE.ISXEVE.EVE();
                g.me = new Me();
            }
        }

        public void Run()
        {
            // set up the handler for events coming back from InnerSpace
            LavishScript.Events.AttachEventTarget(LavishScript.Events.RegisterEvent("OnFrame"), OnFrame);
            LavishScript.Commands.AddCommand("evecmd_update", Update);
            while (true)
            {
                string command = Console.ReadLine();
                lock (lock_)
                {
                    command_queue_.Add(command);
                }
                if (command == "exit")
                    break;
            }
            g.Print("Bye!");
        }

        public int Update(string[] args)
        {
            InnerSpace.Echo("GOT CALLBACK");

            return 0;
        }

        void OnFrame(object sender, LSEventArgs e)
        {
            using (new FrameLock(true))
            {
                Initialize();

                List<string> queue = null;
                lock (lock_)
                {
                    if (command_queue_.Count > 0)
                    {
                        queue = new List<string>(command_queue_);
                        command_queue_.Clear();
                    }
                }

                // first process any commands from the user
                if (queue != null)
                    foreach (string command in queue)
                        RunCommand(command);

                // now go through the states in the state queue until one
                // claims to have handled  the frame
                int i;
                for (i = 0; i < states.Count; i++)
                {
                    State state = states[i];
                    if (state.OnFrame())
                        break;
                }

                if (i == states.Count)
                    i--;

                // remove any states that finished
                for (; i >= 0; i--)
                {
                    State state = states[i];
                    if (state.IsDone())
                    {
                        g.Print("Exiting state: {0} ({1})", state, state.Result);
                        states.RemoveAt(i);
                    }
                }
            }
        }

        void RunCommand(string command)
        {
            if (command == "update")
                LavishScript.ExecuteCommand("execute evecmd_update woot");
            else if (command == "undock")
            {
                State state = new UndockState();
                TryToEnterState(state);
            }
            else if (command == "gates")
            {
                List<Entity> entities = g.eve.GetEntities("GroupID", "10");
                g.Print("Found {0} Stargates:", entities.Count);
                int i = 0;
                foreach (Entity entity in entities)
                {
                    g.Print("#{0}: [{2}] {1}", i, entity.Name, entity.ID);
                    i++;
                }
            }
            else if (command == "stations")
            {
                List<Entity> entities = g.eve.GetEntities("GroupID", "15");
                g.Print("Found {0} Stations:", entities.Count);
                int i = 0;
                foreach (Entity entity in entities)
                {
                    g.Print("#{0}: [{2}] {1}", i, entity.Name, entity.ID);
                    i++;
                }
            }
            else if (command == "missions")
            {
                List<AgentMission> missions = g.eve.GetAgentMissions();
                if (missions != null && missions.Count != 0)
                {
                    g.Print("Found {0} Missions:", missions.Count);
                    int i = 0;
                    foreach (AgentMission mission in missions)
                    {
                        g.Print("#{0}: [{2}] {1}", i, mission.Name, mission.AgentID);
                        i++;
                    }
                }
                else if (missions == null)
                {
                    g.Print("Getting missions failed");
                }
                else
                {
                    g.Print("No missions found");
                }
            }
            else if (command.StartsWith("warp "))
            {
                State state = new WarpState(command);
                TryToEnterState(state);
            }
            else if (command.StartsWith("dock "))
            {
                State state = new DockState(command);
                TryToEnterState(state);
            }
        }

        public void TryToEnterState(State state)
        {
            state.OnFrame();
            if (!state.IsDone())
            {
                g.Print("Entering state: {0}", state);
                states.Insert(0, state);
            }
            else
            {
                g.Print("Failed to enter state: {0} ({1})", state, state.Result);
            }
        }
    }
}
