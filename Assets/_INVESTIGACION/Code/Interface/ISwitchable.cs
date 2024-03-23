/*-----------------------------
 -------------------------------
 Creation Date: 23/03/24
 Author: Victor
 Description: Quest 3 XR App
--------------------------------
-----------------------------*/

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Dev.Bakata{

	/// <summary>
	/// Interface
	/// </summary>

	public interface ISwitchable
	{
		public bool IsActive { get; set; }
		public bool IsLocked { get; set; }
		public bool IsUnlocked { get; set; }
		public void Unlocked();
		public void Activate();
		public void Desactivate();
	}
}