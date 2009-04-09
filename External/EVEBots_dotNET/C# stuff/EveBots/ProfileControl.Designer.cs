namespace EveBots
{
    partial class ProfileControl
    {
        /// <summary> 
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary> 
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Component Designer generated code

        /// <summary> 
        /// Required method for Designer support - do not modify 
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.splitContainer1 = new System.Windows.Forms.SplitContainer();
            this.splitContainer4 = new System.Windows.Forms.SplitContainer();
            this.treeView1 = new System.Windows.Forms.TreeView();
            this._addProfile = new System.Windows.Forms.Button();
            this._removeProfile = new System.Windows.Forms.Button();
            this.splitContainer2 = new System.Windows.Forms.SplitContainer();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.splitContainer3 = new System.Windows.Forms.SplitContainer();
            this._pExecutable = new System.Windows.Forms.MaskedTextBox();
            this._pPath = new System.Windows.Forms.MaskedTextBox();
            this._pName = new System.Windows.Forms.MaskedTextBox();
            this.label3 = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.label1 = new System.Windows.Forms.Label();
            this.groupBox2 = new System.Windows.Forms.GroupBox();
            this._removeCommand = new System.Windows.Forms.Button();
            this._addCommand = new System.Windows.Forms.Button();
            this._pSequence = new System.Windows.Forms.ListView();
            this._Finished = new System.Windows.Forms.Button();
            this.splitContainer1.Panel1.SuspendLayout();
            this.splitContainer1.Panel2.SuspendLayout();
            this.splitContainer1.SuspendLayout();
            this.splitContainer4.Panel1.SuspendLayout();
            this.splitContainer4.Panel2.SuspendLayout();
            this.splitContainer4.SuspendLayout();
            this.splitContainer2.Panel1.SuspendLayout();
            this.splitContainer2.Panel2.SuspendLayout();
            this.splitContainer2.SuspendLayout();
            this.groupBox1.SuspendLayout();
            this.splitContainer3.Panel1.SuspendLayout();
            this.splitContainer3.Panel2.SuspendLayout();
            this.splitContainer3.SuspendLayout();
            this.groupBox2.SuspendLayout();
            this.SuspendLayout();
            // 
            // splitContainer1
            // 
            this.splitContainer1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer1.Location = new System.Drawing.Point(0, 0);
            this.splitContainer1.Name = "splitContainer1";
            // 
            // splitContainer1.Panel1
            // 
            this.splitContainer1.Panel1.Controls.Add(this.splitContainer4);
            // 
            // splitContainer1.Panel2
            // 
            this.splitContainer1.Panel2.Controls.Add(this.splitContainer2);
            this.splitContainer1.Size = new System.Drawing.Size(602, 454);
            this.splitContainer1.SplitterDistance = 200;
            this.splitContainer1.TabIndex = 0;
            // 
            // splitContainer4
            // 
            this.splitContainer4.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer4.Location = new System.Drawing.Point(0, 0);
            this.splitContainer4.Name = "splitContainer4";
            this.splitContainer4.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainer4.Panel1
            // 
            this.splitContainer4.Panel1.Controls.Add(this.treeView1);
            // 
            // splitContainer4.Panel2
            // 
            this.splitContainer4.Panel2.Controls.Add(this._addProfile);
            this.splitContainer4.Panel2.Controls.Add(this._removeProfile);
            this.splitContainer4.Size = new System.Drawing.Size(200, 454);
            this.splitContainer4.SplitterDistance = 383;
            this.splitContainer4.TabIndex = 0;
            // 
            // treeView1
            // 
            this.treeView1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.treeView1.Location = new System.Drawing.Point(0, 0);
            this.treeView1.Name = "treeView1";
            this.treeView1.Size = new System.Drawing.Size(200, 383);
            this.treeView1.TabIndex = 0;
            this.treeView1.AfterSelect += new System.Windows.Forms.TreeViewEventHandler(this.treeView1_AfterSelect);
            // 
            // _addProfile
            // 
            this._addProfile.Dock = System.Windows.Forms.DockStyle.Bottom;
            this._addProfile.Location = new System.Drawing.Point(0, 21);
            this._addProfile.Name = "_addProfile";
            this._addProfile.Size = new System.Drawing.Size(200, 23);
            this._addProfile.TabIndex = 3;
            this._addProfile.Text = "Add Profile";
            this._addProfile.UseVisualStyleBackColor = true;
            // 
            // _removeProfile
            // 
            this._removeProfile.Dock = System.Windows.Forms.DockStyle.Bottom;
            this._removeProfile.Location = new System.Drawing.Point(0, 44);
            this._removeProfile.Name = "_removeProfile";
            this._removeProfile.Size = new System.Drawing.Size(200, 23);
            this._removeProfile.TabIndex = 4;
            this._removeProfile.Text = "Remove Profile";
            this._removeProfile.UseVisualStyleBackColor = true;
            // 
            // splitContainer2
            // 
            this.splitContainer2.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer2.FixedPanel = System.Windows.Forms.FixedPanel.Panel2;
            this.splitContainer2.Location = new System.Drawing.Point(0, 0);
            this.splitContainer2.Name = "splitContainer2";
            this.splitContainer2.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainer2.Panel1
            // 
            this.splitContainer2.Panel1.Controls.Add(this.groupBox1);
            // 
            // splitContainer2.Panel2
            // 
            this.splitContainer2.Panel2.Controls.Add(this._Finished);
            this.splitContainer2.Size = new System.Drawing.Size(398, 454);
            this.splitContainer2.SplitterDistance = 411;
            this.splitContainer2.TabIndex = 0;
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.splitContainer3);
            this.groupBox1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.groupBox1.Location = new System.Drawing.Point(0, 0);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(398, 411);
            this.groupBox1.TabIndex = 0;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "Profile";
            // 
            // splitContainer3
            // 
            this.splitContainer3.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer3.FixedPanel = System.Windows.Forms.FixedPanel.Panel1;
            this.splitContainer3.IsSplitterFixed = true;
            this.splitContainer3.Location = new System.Drawing.Point(3, 16);
            this.splitContainer3.Name = "splitContainer3";
            this.splitContainer3.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainer3.Panel1
            // 
            this.splitContainer3.Panel1.Controls.Add(this._pExecutable);
            this.splitContainer3.Panel1.Controls.Add(this._pPath);
            this.splitContainer3.Panel1.Controls.Add(this._pName);
            this.splitContainer3.Panel1.Controls.Add(this.label3);
            this.splitContainer3.Panel1.Controls.Add(this.label2);
            this.splitContainer3.Panel1.Controls.Add(this.label1);
            // 
            // splitContainer3.Panel2
            // 
            this.splitContainer3.Panel2.Controls.Add(this.groupBox2);
            this.splitContainer3.Size = new System.Drawing.Size(392, 392);
            this.splitContainer3.SplitterDistance = 116;
            this.splitContainer3.TabIndex = 0;
            // 
            // _pExecutable
            // 
            this._pExecutable.Location = new System.Drawing.Point(79, 85);
            this._pExecutable.Name = "_pExecutable";
            this._pExecutable.Size = new System.Drawing.Size(213, 20);
            this._pExecutable.TabIndex = 8;
            this._pExecutable.TextChanged += new System.EventHandler(this._pExecutable_TextChanged);
            // 
            // _pPath
            // 
            this._pPath.Location = new System.Drawing.Point(48, 56);
            this._pPath.Name = "_pPath";
            this._pPath.Size = new System.Drawing.Size(244, 20);
            this._pPath.TabIndex = 7;
            this._pPath.TextChanged += new System.EventHandler(this._pPath_TextChanged);
            // 
            // _pName
            // 
            this._pName.Location = new System.Drawing.Point(48, 22);
            this._pName.Name = "_pName";
            this._pName.Size = new System.Drawing.Size(244, 20);
            this._pName.TabIndex = 6;
            this._pName.TextChanged += new System.EventHandler(this._pName_TextChanged);
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(7, 88);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(66, 13);
            this.label3.TabIndex = 5;
            this.label3.Text = "Executable :";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(7, 59);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(35, 13);
            this.label2.TabIndex = 4;
            this.label2.Text = "Path :";
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(4, 25);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(41, 13);
            this.label1.TabIndex = 3;
            this.label1.Text = "Name :";
            // 
            // groupBox2
            // 
            this.groupBox2.Controls.Add(this._removeCommand);
            this.groupBox2.Controls.Add(this._addCommand);
            this.groupBox2.Controls.Add(this._pSequence);
            this.groupBox2.Dock = System.Windows.Forms.DockStyle.Fill;
            this.groupBox2.Location = new System.Drawing.Point(0, 0);
            this.groupBox2.Name = "groupBox2";
            this.groupBox2.Size = new System.Drawing.Size(392, 272);
            this.groupBox2.TabIndex = 3;
            this.groupBox2.TabStop = false;
            this.groupBox2.Text = "Startup Sequence";
            // 
            // _removeCommand
            // 
            this._removeCommand.Dock = System.Windows.Forms.DockStyle.Top;
            this._removeCommand.Location = new System.Drawing.Point(3, 215);
            this._removeCommand.Name = "_removeCommand";
            this._removeCommand.Size = new System.Drawing.Size(386, 23);
            this._removeCommand.TabIndex = 4;
            this._removeCommand.Text = "Remove Command";
            this._removeCommand.UseVisualStyleBackColor = true;
            this._removeCommand.Click += new System.EventHandler(this._removeCommand_Click);
            // 
            // _addCommand
            // 
            this._addCommand.Dock = System.Windows.Forms.DockStyle.Top;
            this._addCommand.Location = new System.Drawing.Point(3, 192);
            this._addCommand.Name = "_addCommand";
            this._addCommand.Size = new System.Drawing.Size(386, 23);
            this._addCommand.TabIndex = 3;
            this._addCommand.Text = "Add Command";
            this._addCommand.UseVisualStyleBackColor = true;
            this._addCommand.Click += new System.EventHandler(this._addCommand_Click);
            // 
            // _pSequence
            // 
            this._pSequence.Dock = System.Windows.Forms.DockStyle.Top;
            this._pSequence.FullRowSelect = true;
            this._pSequence.LabelEdit = true;
            this._pSequence.Location = new System.Drawing.Point(3, 16);
            this._pSequence.MultiSelect = false;
            this._pSequence.Name = "_pSequence";
            this._pSequence.Size = new System.Drawing.Size(386, 176);
            this._pSequence.TabIndex = 1;
            this._pSequence.UseCompatibleStateImageBehavior = false;
            this._pSequence.View = System.Windows.Forms.View.Details;
            this._pSequence.AfterLabelEdit += new System.Windows.Forms.LabelEditEventHandler(this._pSequence_AfterLabelEdit);
            this._pSequence.SelectedIndexChanged += new System.EventHandler(this._pSequence_SelectedIndexChanged);
            // 
            // _Finished
            // 
            this._Finished.Dock = System.Windows.Forms.DockStyle.Fill;
            this._Finished.Location = new System.Drawing.Point(0, 0);
            this._Finished.Name = "_Finished";
            this._Finished.Size = new System.Drawing.Size(398, 39);
            this._Finished.TabIndex = 0;
            this._Finished.Text = "Done";
            this._Finished.UseVisualStyleBackColor = true;
            this._Finished.Click += new System.EventHandler(this._Finished_Click);
            // 
            // ProfileControl
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.Controls.Add(this.splitContainer1);
            this.Name = "ProfileControl";
            this.Size = new System.Drawing.Size(602, 454);
            this.splitContainer1.Panel1.ResumeLayout(false);
            this.splitContainer1.Panel2.ResumeLayout(false);
            this.splitContainer1.ResumeLayout(false);
            this.splitContainer4.Panel1.ResumeLayout(false);
            this.splitContainer4.Panel2.ResumeLayout(false);
            this.splitContainer4.ResumeLayout(false);
            this.splitContainer2.Panel1.ResumeLayout(false);
            this.splitContainer2.Panel2.ResumeLayout(false);
            this.splitContainer2.ResumeLayout(false);
            this.groupBox1.ResumeLayout(false);
            this.splitContainer3.Panel1.ResumeLayout(false);
            this.splitContainer3.Panel1.PerformLayout();
            this.splitContainer3.Panel2.ResumeLayout(false);
            this.splitContainer3.ResumeLayout(false);
            this.groupBox2.ResumeLayout(false);
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.SplitContainer splitContainer1;
        private System.Windows.Forms.TreeView treeView1;
        private System.Windows.Forms.SplitContainer splitContainer2;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.Button _Finished;
        private System.Windows.Forms.SplitContainer splitContainer3;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.MaskedTextBox _pPath;
        private System.Windows.Forms.MaskedTextBox _pName;
        private System.Windows.Forms.GroupBox groupBox2;
        private System.Windows.Forms.ListView _pSequence;
        private System.Windows.Forms.MaskedTextBox _pExecutable;
        private System.Windows.Forms.SplitContainer splitContainer4;
        private System.Windows.Forms.Button _addProfile;
        private System.Windows.Forms.Button _removeProfile;
        private System.Windows.Forms.Button _removeCommand;
        private System.Windows.Forms.Button _addCommand;
    }
}
